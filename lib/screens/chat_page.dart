import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/home_al_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:speech_to_text/speech_to_text.dart';


const String baseUrl = "http://192.168.10.11:3000";

class ChatPage extends StatefulWidget {
  final String detectedEmotion;
  final bool isFromContinue; // 🔥 NEW

  const ChatPage({
    super.key,
    required this.detectedEmotion,
    this.isFromContinue = false, // default normal chat
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
  
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin {
      String previousEmotion = "";
      late String currentEmotion;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isListening = false;
  late SpeechToText _speechToText;

  Future<void> endChat() async {
    try {
      await http.post(
        Uri.parse("$baseUrl/end-chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": FirebaseAuth.instance.currentUser!.uid,
        }),
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home_al',
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chat ended successfully"),
          duration: Duration(seconds: 2),
        ),
      );

      _scrollToBottom(); // ✅ INSIDE function

    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to end chat"),
        ),
      );
    }
  }

  bool _isLoading = false;
  bool _showIntroCard = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _speechToText = SpeechToText();
    currentEmotion = widget.detectedEmotion;
    previousEmotion = widget.detectedEmotion;

    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();


    // 🔥 ADD THIS BELOW
    if (widget.isFromContinue) {
      _sendInitialMessage();
    }
  }


  @override
  void dispose() {
    
    _controller.dispose();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    context.read<ThemeNotifier>().toggleTheme();
  }

  void _goBack() {
    Navigator.pop(context);
  }

  // 🔥 NEW FUNCTION (ADD THIS ABOVE OR BELOW sendMessage)
  Future<void> _sendInitialMessage() async {
    setState(() {
      _showIntroCard = false;
    });

    final user = FirebaseAuth.instance.currentUser;

    final summaryRef = FirebaseDatabase.instance
        .ref("users/${user!.uid}/chat_memory/summary");

    final topicRef = FirebaseDatabase.instance
        .ref("users/${user.uid}/chat_memory/topic");

    final summarySnap = await summaryRef.get();
    final topicSnap = await topicRef.get();

    String summary = "";
    String topic = "";

    if (summarySnap.exists && summarySnap.value != null) {
      summary = summarySnap.value.toString();
    }

    if (topicSnap.exists && topicSnap.value != null) {
      topic = topicSnap.value.toString();
    }

    // 🔥 Clean topic length
    if (topic.length > 60) {
      topic = topic.substring(0, 60) + "...";
    }

    String introMessage;

    if (topic.isNotEmpty) {
      introMessage = "How are things going with $topic now?";
    } else if (summary.isNotEmpty) {
      introMessage =
          "Earlier you mentioned \"$summary\". How do you feel now?";
    } else {
      introMessage = "Welcome back. How are you feeling now?";
    }

    setState(() {
      _messages.add({
        "role": "bot",
        "text": introMessage,
      });
    });

    _scrollToBottom();
  }

  String? detectEmotionFromText(String text) {
    text = text.toLowerCase();

    if (text.contains("better") || text.contains("fine") || text.contains("okay")) {
      return "neutral";
    }

    if (text.contains("happy") || text.contains("good") || text.contains("great")) {
      return "happy";
    }

    if (text.contains("sad") || text.contains("tired") || text.contains("bad")) {
      return "sad";
    }

    if (text.contains("angry") || text.contains("annoyed") || text.contains("frustrated")) {
      return "anger";
    }

    if (text.contains("scared") || text.contains("worried") || text.contains("afraid")) {
      return "fear";
    }

    return null; // no change detected
  }

  bool checkEmotionUpgrade(String oldEmotion, String newEmotion) {
  const order = ["sad", "fear", "anger", "neutral", "happy"];

  int oldIndex = order.indexOf(oldEmotion);
  int newIndex = order.indexOf(newEmotion);

  return newIndex > oldIndex;
}

// ================== EXISTING FUNCTION ==================

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final oldEmotion = currentEmotion;

    setState(() {
      _messages.add({"role": "user", "text": text});
      _isLoading = true;
      _showIntroCard = false;
    });

    _controller.clear();
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": FirebaseAuth.instance.currentUser!.uid,
          "emotion": currentEmotion, // optional now
          "message": text,
          "useMemory": widget.isFromContinue,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          currentEmotion = data["emotion"];
        });

        if (data["statement"] != null && data["statement"].isNotEmpty) {
          _messages.add({"role": "bot", "text": data["statement"]});
        }

        if (data["question"] != null && data["question"].isNotEmpty) {
          _messages.add({"role": "bot", "text": data["question"]});
        }

        if (checkEmotionUpgrade(oldEmotion, currentEmotion)) {
          _messages.add({
            "role": "bot",
            "text": "You seem to be feeling a bit better now."
          });
        }
      } else {
        _addErrorMessage();
      }
    } catch (_) {
      _addErrorMessage();
    }

    setState(() => _isLoading = false);
    _scrollToBottom();
  }

  Future<void> startListening() async {
    bool available = await _speechToText.initialize();

    if (!available) {
      print("Speech not available");
      return;
    }

    setState(() => _isListening = true);

    _speechToText.listen(
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });

        // 🔥 AUTO SEND
        if (result.finalResult) {
          stopListening();

          if (_controller.text.trim().isNotEmpty) {
            sendMessage();
          }
        }
      },
    );
  }

  void stopListening() {
    _speechToText.stop();
    setState(() => _isListening = false);
  }

  void _addErrorMessage() {
    setState(() {
      _messages.add({"role": "bot", "text": "Connection issue. Try again."});
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessage(Map<String, String> message, bool isDark) {
    final isUser = message["role"] == "user";

    final gradient = isUser
        ? (isDark
            ? [const Color(0xFF8B7FFF), const Color(0xFFB4A7FF)]
            : [const Color(0xFF0A7EA4), const Color(0xFF3DA5C8)])
        : (isDark
            ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]
            : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)]);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 10,
            )
          ],
        ),
        child: Text(
          message["text"] ?? "",
          style: TextStyle(
            color: isUser
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const _TypingDots(),
      ),
    );
  }

  Widget _buildHeaderIcon({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.1)]
                : [const Color(0xFF2C3E50).withOpacity(0.2),
                   const Color(0xFF2C3E50).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.20)),
        ),
        child: Icon(
          icon,
          size: 22,
          color: isDark ? Colors.white : const Color(0xFF2C3E50),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? const [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C3E64)]
                : const [Color(0xFFa8edea), Color(0xFFfed6e3),
                         Color(0xFFa6c1ee), Color(0xFFfbc2eb)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Glitter background
            ...List.generate(18, (i) {
              final particleSize = 4.0 + math.Random().nextDouble() * 6;
              final x = math.Random().nextDouble() * size.width;
              final y = math.Random().nextDouble() * size.height * 0.8;

              return Positioned(
                left: x,
                top: y,
                child: Container(
                  width: particleSize,
                  height: particleSize,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF8CC8FF).withOpacity(0.6)
                        : Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),

            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (_, __) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: SafeArea(
                    child: Column(
                      children: [
                        // HEADER (Same as EmotionScanPage)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeaderIcon(
                                icon: Icons.arrow_back,
                                onTap: _goBack,
                                isDark: isDark,
                              ),

                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      "Emotion Chat",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF2C3E50),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      currentEmotion,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white70
                                            : const Color(0xFF2C3E50).withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 🔥 GROUP RIGHT SIDE BUTTONS
                              Row(
                                children: [
                                  _buildHeaderIcon(
                                    icon: Icons.stop_circle,
                                    onTap: endChat,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(width: 8), // spacing
                                  _buildHeaderIcon(
                                    icon: isDark
                                        ? Icons.wb_sunny
                                        : Icons.nightlight_round,
                                    onTap: _toggleTheme,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Intro Card
                        AnimatedSwitcher(
                          duration:
                              const Duration(milliseconds: 400),
                          child: _showIntroCard
                              ? Container(
                                  key:
                                      const ValueKey("intro"),
                                  margin:
                                      const EdgeInsets
                                              .symmetric(
                                          horizontal: 20),
                                  padding:
                                      const EdgeInsets.all(
                                          16),
                                  decoration:
                                      BoxDecoration(
                                    color: isDark
                                        ? Colors.white
                                            .withOpacity(
                                                0.08)
                                        : Colors.white
                                            .withOpacity(
                                                0.85),
                                    borderRadius:
                                        BorderRadius
                                            .circular(18),
                                  ),
                                  child: Text(
                                    "Talk about how you're feeling. I'm here to listen.",
                                    textAlign:
                                        TextAlign.center,
                                    style: TextStyle(
                                      fontWeight:
                                          FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : Colors
                                              .black87,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        const SizedBox(height: 10),

// 💬 CHAT MESSAGES
Expanded(
  child: ListView.builder(
    controller: _scrollController,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    itemCount: _messages.length + (_isLoading ? 1 : 0),
    itemBuilder: (context, index) {
      if (index < _messages.length) {
        return _buildMessage(_messages[index], isDark);
      } else {
        return _buildTypingBubble(isDark);
      }
    },
  ),
),

// 🔽 INPUT AT BOTTOM
SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: TextField(
              controller: _controller,
              style: TextStyle(
                  color: isDark ? Colors.white : Colors.black),
              decoration: const InputDecoration(
                hintText: "Type or speak...",
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => sendMessage(),
            ),
          ),
        ),

            const SizedBox(width: 8),

            // 🎤 MIC BUTTON
            GestureDetector(
              onTap: () {
                if (_isListening) {
                  stopListening();
                } else {
                  startListening();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isListening ? Colors.red : Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // SEND BUTTON
            GestureDetector(
              onTap: sendMessage,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [
                            Color(0xFF8B7FFF),
                            Color(0xFFB4A7FF)
                          ]
                        : const [
                            Color(0xFF0A7EA4),
                            Color(0xFF3DA5C8)
                          ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _dot(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        double value =
            math.sin((_controller.value * 2 * math.pi) + (index * 0.8));
        double opacity = (value + 1) / 2;

        return Opacity(
          opacity: opacity,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: CircleAvatar(
              radius: 4,
              backgroundColor: Colors.grey,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(0),
        _dot(1),
        _dot(2),
      ],
    );
  }
}