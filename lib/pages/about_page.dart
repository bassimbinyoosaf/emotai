// lib/pages/about_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // 👈 Added for ThemeNotifier

import '../widgets/navbar.dart';

// Import centralized ThemeNotifier from app_theme.dart
import '../theme/app_theme.dart'; 

import '../utils/android_toast.dart';


// GlitterParticle (unchanged)
class GlitterParticle extends StatefulWidget {
  final double size;
  final Color color;
  final double initialX;
  final double initialY;

  const GlitterParticle({
    Key? key,
    required this.size,
    required this.color,
    required this.initialX,
    required this.initialY,
  }) : super(key: key);

  @override
  State<GlitterParticle> createState() => _GlitterParticleState();
}

class _GlitterParticleState extends State<GlitterParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _translateY;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.8)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 33.3,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 0.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 33.3,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.4,
      ),
    ]).animate(_controller);

    _translateY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -30.0)
            .chain(CurveTween(curve: Curves.linear)),
        weight: 66.7,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 33.3,
      ),
    ]).animate(_controller);

    Future.delayed(Duration(milliseconds: (math.Random().nextDouble() * 2000).toInt()), () {
      if (mounted) {
        _controller.repeat();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: widget.initialX,
          top: widget.initialY + _translateY.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }
}

// InfoSection (unchanged)
class InfoSection extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  final bool isDark;

  const InfoSection({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.isDark,
  }) : super(key: key);

  @override
  State<InfoSection> createState() => _InfoSectionState();
}

class _InfoSectionState extends State<InfoSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _slideAnim = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnim.value, 0),
          child: Opacity(
            opacity: _opacityAnim.value,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDark
                            ? [
                                const Color(0xFF8B7FFF).withOpacity(0.35),
                                const Color(0xFF8B7FFF).withOpacity(0.15),
                              ]
                            : [
                                const Color(0xFF6C63FF).withOpacity(0.25),
                                const Color(0xFF6C63FF).withOpacity(0.1),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(
                      widget.icon,
                      size: 28,
                      color: widget.isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark ? Colors.white : const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.description,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.43,
                            color: widget.isDark
                                ? const Color(0xFFFFFFFF).withOpacity(0.8)
                                : const Color(0xFF2C3E50).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// AboutPage — now with theme toggle!
class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with TickerProviderStateMixin {
  DateTime? _lastBackPressed;

  late AnimationController _fadeController;
  late AnimationController _headerSlideController;
  late Animation<double> _fadeAnim;
  late Animation<double> _headerSlide;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _headerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _headerSlide = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(parent: _headerSlideController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _headerSlideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _headerSlideController.dispose();
    super.dispose();
  }

  // Toggle theme — uses centralized ThemeNotifier
  void _toggleTheme() {
    context.read<ThemeNotifier>().toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final sections = [
      {
        'icon': Icons.auto_awesome_outlined,
        'title': 'Emotion Recognition',
        'description':
            'Advanced AI technology that detects and analyzes human emotions through facial expressions and micro-movements in real-time.',
      },
      {
        'icon': Icons.flash_on_outlined,
        'title': 'Smart Analysis',
        'description':
            'Neural networks trained on thousands of emotional patterns to provide accurate insights into your emotional state.',
      },
      {
        'icon': Icons.people_outline,
        'title': 'Better Communication',
        'description':
            'Enhance your emotional intelligence and improve relationships by understanding emotions better in daily interactions.',
      },
    ];

    return WillPopScope(
  onWillPop: () async {
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      AndroidToast.show(
        context,
        "Press back again to exit",
      );

      return false;
    }

    return true;
  },
  child: Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF0F2027),
                        const Color(0xFF203A43),
                        const Color(0xFF2C5364),
                      ]
                    : [
                        const Color(0xFFa8edea),
                        const Color(0xFFfed6e3),
                        const Color(0xFFa6c1ee),
                        const Color(0xFFfbc2eb),
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Floating Particles
                ...List.generate(15, (i) {
                  final particleSize = 4.0 + math.Random().nextDouble() * 6;
                  final x = math.Random().nextDouble() * size.width;
                  final y = math.Random().nextDouble() * size.height * 0.7;
                  final colorsArr = isDark
                      ? [
                          const Color(0xFF8CC8FF).withOpacity(0.6),
                          const Color(0xFFB496FF).withOpacity(0.55),
                        ]
                      : [
                          const Color(0xFFFFFFFF).withOpacity(0.9),
                          const Color(0xFFF0F0FF).withOpacity(0.85),
                        ];
                  final color = colorsArr[math.Random().nextInt(colorsArr.length)];

                  return GlitterParticle(
                    key: ValueKey(i),
                    size: particleSize,
                    color: color,
                    initialX: x,
                    initialY: y,
                  );
                }),

                // Main Content
                AnimatedBuilder(
                  animation: Listenable.merge([_fadeAnim, _headerSlide]),
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnim.value,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
                        children: [
                          // Header with theme toggle
                          Transform.translate(
                            offset: Offset(0, _headerSlide.value),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Title + Subtitle
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'About',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : const Color(0xFF2C3E50),
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Discover EmotAI',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? const Color(0xFFFFFFFF).withOpacity(0.85)
                                              : const Color(0xFF2C3E50).withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Theme toggle button
                                InkWell(
                                  onTap: _toggleTheme,
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [
                                                const Color(0xFFFFFFFF).withOpacity(0.3),
                                                const Color(0xFFFFFFFF).withOpacity(0.1),
                                              ]
                                            : [
                                                const Color(0xFF0A7EA4).withOpacity(0.2),
                                                const Color(0xFF0A7EA4).withOpacity(0.1),
                                              ],
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFFFFFFFF).withOpacity(0.3)
                                            : const Color(0xFF0A7EA4).withOpacity(0.3),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      isDark ? Icons.wb_sunny : Icons.nightlight_round,
                                      color: isDark ? Colors.white : const Color(0xFF0A7EA4),
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // App Logo Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFFFFFFFF).withOpacity(0.2),
                                        const Color(0xFFFFFFFF).withOpacity(0.05),
                                      ]
                                    : [
                                        const Color(0xFF2C3E50).withOpacity(0.15),
                                        const Color(0xFF2C3E50).withOpacity(0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isDark
                                              ? [
                                                  const Color(0xFF8B7FFF).withOpacity(0.4),
                                                  const Color(0xFF8B7FFF).withOpacity(0.2),
                                                ]
                                              : [
                                                  const Color(0xFF6C63FF).withOpacity(0.3),
                                                  const Color(0xFF6C63FF).withOpacity(0.15),
                                                ],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.mood_outlined,
                                        size: 48,
                                        color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'EmotAI',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Understanding emotions through intelligent technology',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFFFFFFF).withOpacity(0.85)
                                        : const Color(0xFF2C3E50).withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 42),

                          // Info Sections
                          ...sections.asMap().entries.map((entry) {
                            final index = entry.key;
                            final section = entry.value;
                            return InfoSection(
                              icon: section['icon'] as IconData,
                              title: section['title'] as String,
                              description: section['description'] as String,
                              delay: 400 + index * 150,
                              isDark: isDark,
                            );
                          }).toList(),

                          const SizedBox(height: 24),

                          // Technology Stack
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFFFFFFFF).withOpacity(0.15),
                                        const Color(0xFFFFFFFF).withOpacity(0.05),
                                      ]
                                    : [
                                        const Color(0xFF2C3E50).withOpacity(0.12),
                                        const Color(0xFF2C3E50).withOpacity(0.05),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BUILT WITH',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: ['TensorFlow', 'Flutter', 'Deep Learning'].map((tech) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF8B7FFF).withOpacity(0.2)
                                            : const Color(0xFF6C63FF).withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tech,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Footer
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF8B7FFF).withOpacity(0.15)
                                      : const Color(0xFF6C63FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  'v1.0.0',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                    color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '© 2025 EmotAI',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFFFFFFF).withOpacity(0.6)
                                      : const Color(0xFF2C3E50).withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Navbar
          const Navbar(),
        ],
      ),
    )
  );
  }
}