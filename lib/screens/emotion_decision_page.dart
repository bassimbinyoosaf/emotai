import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'timer_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class EmotionDecisionPage extends StatefulWidget {
  final String detectedEmotion;

  const EmotionDecisionPage({
    super.key,
    required this.detectedEmotion,
  });

  @override
  State<EmotionDecisionPage> createState() => _EmotionDecisionPageState();
}

class _EmotionDecisionPageState extends State<EmotionDecisionPage> {

  List<String> _userInterests = [];
  List<Map<String, String>> _suggestions = [];
  bool _loadingSuggestions = true;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
  }

  // ================= LINK =================
  Future<void> _openLink(String url) async {
    final uri = Uri.parse(url);

    try {
      final success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!success) throw "Could not launch";

    } catch (e) {
      debugPrint("Launch error: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to open link")),
      );
    }
  }

  // ================= LOAD =================
  Future<void> _loadUserInterests() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snap = await FirebaseDatabase.instance
          .ref()
          .child("users")
          .child(user.uid)
          .child("interests")
          .get();

      if (snap.exists) {
        final data = Map<String, dynamic>.from(snap.value as Map);

        _userInterests = data.entries
            .where((e) => e.value == true)
            .map((e) => e.key.split("|").last)
            .toList();

        _generateSuggestions();
      }
    } catch (e) {
      debugPrint("Interest load error: $e");
    }

    setState(() => _loadingSuggestions = false);
  }

  // ================= GENERATE =================
  void _generateSuggestions() {
    if (_userInterests.isEmpty) return;

    _userInterests.shuffle();

    // pick any 2 random interests (no bias)
    final selected = _userInterests.take(2).toList();

    _suggestions = selected.map((interest) {
      final i = interest.toLowerCase();

      return {
        "text": _buildLinkSuggestion(interest),
        "interest": i,
        "isLink": "true",
      };
    }).toList();
  }

  // ================= NORMAL =================
  String _buildNormalSuggestion(String interest) {
    final i = interest.toLowerCase();

    if (i.contains("music")) return "Relax with some $interest music 🎧";
    if (i.contains("art") || i.contains("photography")) return "Spend time doing $interest 🎨";
    if (i.contains("dance")) return "Try some $interest moves 💃";
    if (i.contains("sports") || i.contains("football") || i.contains("cricket")) {
      return "Try playing some $interest 🏃";
    }

    return "Spend time with $interest 🙂";
  }

  // ================= LINK =================
  String _buildLinkSuggestion(String interest) {
    final i = interest.toLowerCase();

    if (i.contains("football")) return "Watch live football matches ⚽";
    if (i.contains("cricket")) return "Check live cricket matches 🏏";
    if (i.contains("basketball")) return "Watch basketball highlights 🏀";
    if (i.contains("sports")) return "Watch trending sports matches 🏟️";

    return "Explore $interest online 🔍";
  }

  // ================= CLICK =================
  void _handleSuggestionClick(String interest) {

    if (interest.contains("football")) {
        _openLink("https://www.beinsports.com/en/football/");
      } 

      else if (interest.contains("cricket")) {
        _openLink("https://www.cricbuzz.com/cricket-videos");
      } 

      // 🏀 Basketball (separate)
      else if (interest.contains("basketball")) {
        _openLink("https://www.nba.com/games");
      } 

      // 🏟️ General sports (separate)
      else if (interest.contains("sports")) {
        _openLink("https://www.espn.com/watch/");
      } 

      // 🎧 Music (separate)
      else if (interest.contains("music")) {
        _openLink("https://open.spotify.com/");
      } 

      // 💃 Dance (separate)
      else if (interest.contains("dance")) {
        _openLink("https://www.redbull.com/int-en/tags/dance");
      } 

      // 📸 Photography (search results)
      else if (interest.contains("photography")) {
        _openLink("https://www.pinterest.com/search/pins/?q=photography");
      } 

      // 🎨 Art (search results)
      else if (interest.contains("art")) {
        _openLink("https://www.pinterest.com/search/pins/?q=art");
      } 

      else {
        _openLink("https://www.google.com");
      }
    
  }

  bool _isNegativeEmotion(String e) =>
      e.contains("sad") || e.contains("anger") || e.contains("fear") || e.contains("disgust");

  bool _isPositiveEmotion(String e) =>
      e.contains("happy") || e.contains("joy") || e.contains("surprise");

  // ================= SUGGESTION UI =================
  Widget _buildSuggestions() {
    if (_loadingSuggestions) return const CircularProgressIndicator();

    return Column(
      children: _suggestions.map((item) {
        final isLink = item["isLink"] == "true";

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Text(
                "• ${item["text"]}",
                textAlign: TextAlign.center,
              ),

              if (isLink)
                GestureDetector(
                  onTap: () => _handleSuggestionClick(item["interest"]!),
                  child: const Text(
                    "🔗 Go to site",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {

    final emotion = widget.detectedEmotion.toLowerCase();
    final isNegative = _isNegativeEmotion(emotion);
    final isPositive = _isPositiveEmotion(emotion);

    if (isPositive) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  const Icon(
                    Icons.sentiment_very_satisfied,
                    size: 70,
                    color: Colors.green,
                  ),

                  const SizedBox(height: 25),

                  Text(
                    "We detected: ${widget.detectedEmotion}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "You seem to be feeling good today!",
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  _buildSuggestions(),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatPage(
                            detectedEmotion: widget.detectedEmotion,
                          ),
                        ),
                      ),
                      child: const Text("Talk to Chatbot"),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ),
      );
    }

    
    if (isNegative) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Icon(Icons.psychology_alt, size: 70, color: Colors.deepPurple),
                const SizedBox(height: 25),

                Text("We detected: ${widget.detectedEmotion}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),

                const SizedBox(height: 20),
                _buildSuggestions(),

                const SizedBox(height: 20),

                const Text(
                  "Would you like to talk to the chatbot about how you're feeling?",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(detectedEmotion: widget.detectedEmotion),
                    ),
                  ),
                  child: const Text("Yes"),
                ),

                const SizedBox(height: 12),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TimerPage()),
                  ),
                  child: const Text("Maybe Later"),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () => _showMedicalSuggestion(context),
                  child: const Text("No"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Text("Detected emotion: ${widget.detectedEmotion}"),
      ),
    );
  }

  void _showMedicalSuggestion(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Support Recommendation"),
        content: const Text("Consider reaching out to someone you trust."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Okay"))
        ],
      ),
    );
  }
}