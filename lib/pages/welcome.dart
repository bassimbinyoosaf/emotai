import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _scrollAnim;

  String getUsername() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "User";
    return user.displayName ??
        user.email?.split("@").first ??
        "User";
  }

  @override
  void initState() {
    super.initState();

    _scrollAnim = AnimationController(
      vsync: this,
      lowerBound: 0,
      upperBound: 100000,
    );

    _scrollController.addListener(() {
      _scrollAnim.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final username = getUsername();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 🎯 Button colors
    final buttonColor =
        isDark ? const Color(0xFF8B7FFF) : const Color(0xFFB4A7FF);

    return Scaffold(
      body: Stack(
        children: [
          // 🌈 BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [
                        Color(0xFF0F2027),
                        Color(0xFF203A43),
                        Color(0xFF2C5364),
                      ]
                    : const [
                        Color(0xFFa8edea),
                        Color(0xFFfed6e3),
                        Color(0xFFa6c1ee),
                        Color(0xFFfbc2eb),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ✨ GLITTER PARTICLES
          ...List.generate(18, (i) {
            final random = math.Random(i);
            final size = 6.0 + random.nextDouble() * 8;
            final x =
                random.nextDouble() * MediaQuery.of(context).size.width;
            final y =
                random.nextDouble() * MediaQuery.of(context).size.height;

            final colors = isDark
                ? [
                    const Color(0xFF7dd3fc).withOpacity(0.25),
                    const Color(0xFFc4b5fd).withOpacity(0.25),
                    const Color(0xFF67e8f9).withOpacity(0.25),
                  ]
                : [
                    const Color(0xFFFFFFFF).withOpacity(0.95),
                    const Color(0xFFF0F0FF).withOpacity(0.9),
                    const Color(0xFFFFF0FF).withOpacity(0.85),
                  ];

            final color = colors[random.nextInt(colors.length)];

            return GlitterParticle(
              key: ValueKey(i),
              size: size,
              color: color,
              initialX: x,
              initialY: y,
              index: i,
              scrollY: _scrollAnim,
            );
          }),

          // 🧱 MAIN CONTENT
          SafeArea(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                20,
                24, // ✅ MATCH HOME TOP OFFSET
                20,
                120,
              ),
              children: [
                // ✅ HEADER — NOW SAME POSITION AS HOME
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'EmotAI',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFF11181C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track Your Feelings',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white70
                            : Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // 💎 WELCOME CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 30,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.white.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? const Color(0xFF7C83FD)
                                      .withOpacity(0.25)
                                  : const Color(0xFF7C83FD)
                                      .withOpacity(0.2),
                            ),
                            child: const Icon(
                              Icons.emoji_emotions_outlined,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 26),

                          Text(
                            "Welcome, $username 👋",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF11181C),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            "Understand your emotions better with AI powered analysis.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black.withOpacity(0.65),
                            ),
                          ),

                          const SizedBox(height: 34),

                          // 🎯 BUTTON COLOR MATCHED
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Continue",
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
