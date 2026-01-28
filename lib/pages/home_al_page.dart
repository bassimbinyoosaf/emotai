// lib/pages/home_al_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';
import '../utils/android_toast.dart';

// GlitterParticle (unchanged)
class GlitterParticle extends StatefulWidget {
  final double size;
  final Color color;
  final double initialX;
  final double initialY;
  final int index;
  final Animation<double> scrollY;

  const GlitterParticle({
    Key? key,
    required this.size,
    required this.color,
    required this.initialX,
    required this.initialY,
    required this.index,
    required this.scrollY,
  }) : super(key: key);

  @override
  State<GlitterParticle> createState() => _GlitterParticleState();
}

class _GlitterParticleState extends State<GlitterParticle>
    with TickerProviderStateMixin {
  late AnimationController _opacityController;
  late AnimationController _scaleController;
  late AnimationController _floatController;
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<Offset> _float;

  @override
  void initState() {
    super.initState();

    _opacityController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + (math.Random().nextDouble() * 2000).toInt()),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500 + (math.Random().nextDouble() * 2000).toInt()),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.7 + math.Random().nextDouble() * 0.3)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7 + math.Random().nextDouble() * 0.3, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_opacityController);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 60,
      ),
    ]).animate(_scaleController);

    _floatController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 10000 + (math.Random().nextDouble() * 5000).toInt()),
    );

    final xRange = 12.0 + math.Random().nextDouble() * 18;
    final yRange = 15.0 + math.Random().nextDouble() * 25;

    _float = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: Offset(xRange, yRange))
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(xRange, yRange), end: Offset(-xRange, -yRange))
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset(-xRange, -yRange), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 25,
      ),
    ]).animate(_floatController);

    _startAnimations();
  }

  void _startAnimations() {
    Future.delayed(Duration(milliseconds: (math.Random().nextDouble() * 3000).toInt()), () {
      if (mounted) {
        _opacityController.repeat();
        _scaleController.repeat();
        _floatController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _opacityController.dispose();
    _scaleController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_opacity, _scale, _float, widget.scrollY]),
      builder: (context, child) {
        final parallaxY = widget.scrollY.value * -0.2 * (0.4 + widget.index * 0.18);
        final parallaxX = widget.scrollY.value * 0.04 * (widget.index % 2 == 0 ? -1 : 1);

        return Positioned(
          left: widget.initialX + _float.value.dx + parallaxX,
          top: widget.initialY + _float.value.dy + parallaxY,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.6),
                      blurRadius: widget.size * 1.2,
                      spreadRadius: widget.size * 0.1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// FeatureCard (unchanged)
class FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final int delay;
  final bool isDark;

  const FeatureCard({
    Key? key,
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
    required this.isDark,
  }) : super(key: key);

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideY = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
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
          offset: Offset(0, _slideY.value),
          child: Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: _opacity.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isDark
                        ? [
                            const Color(0xFFFFFFFF).withOpacity(0.22),
                            const Color(0xFFFFFFFF).withOpacity(0.06),
                          ]
                        : [
                            const Color(0xFF2C3E50).withOpacity(0.16),
                            const Color(0xFF2C3E50).withOpacity(0.06),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFFFFF).withOpacity(0.22),
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: widget.isDark
                                ? [
                                    const Color(0xFF8B7FFF).withOpacity(0.3),
                                    const Color(0xFF6C63FF).withOpacity(0.15),
                                  ]
                                : [
                                    const Color(0xFF0A7EA4).withOpacity(0.25),
                                    const Color(0xFF0A7EA4).withOpacity(0.12),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          widget.icon,
                          size: 28,
                          color: widget.isDark ? const Color(0xFF8B7FFF) : const Color(0xFF0A7EA4),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: widget.isDark ? Colors.white : const Color(0xFF11181C),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.description,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.46,
                                color: widget.isDark
                                    ? const Color(0xFFFFFFFF).withOpacity(0.8)
                                    : const Color(0xFF687076),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ✅ Renamed to HomeALPage to match route '/home_al'
class HomeALPage extends StatefulWidget {
  const HomeALPage({Key? key}) : super(key: key);

  @override
  State<HomeALPage> createState() => _HomeALPageState();
}

class _HomeALPageState extends State<HomeALPage> with TickerProviderStateMixin {
  DateTime? _lastBackPressed;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scrollController;
  late AnimationController _heroController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;
  late Animation<double> _scrollY;
  late Animation<double> _heroScale;
  late Animation<double> _heroOpacity;

  final ScrollController _listScrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnim = Tween<double>(begin: -40.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    
    _scrollY = Tween<double>(begin: 0.0, end: 0.0).animate(_scrollController);

    _heroScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOutCubic),
    );

    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.easeOut),
    );

    _fadeController.forward();
    _slideController.forward();
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _heroController.forward();
    });

    _listScrollController.addListener(() {
      _scrollController.value = _listScrollController.offset / 1000;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scrollController.dispose();
    _heroController.dispose();
    _listScrollController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    context.read<ThemeNotifier>().toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Personalized welcome logic
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedInAndVerified = user != null && user.emailVerified;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final welcomeText = isLoggedInAndVerified ? 'Welcome, $displayName👋' : 'Track Your Feelings';

    final features = [
      {
        'icon': Icons.camera_alt_outlined,
        'title': 'Real-Time Detection',
        'description': 'Instantly capture and analyze emotions using advanced facial recognition technology.',
      },
      {
        'icon': Icons.bar_chart_outlined,
        'title': 'Detailed Analytics',
        'description': 'Track your emotional patterns over time with comprehensive visual insights.',
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Privacy First',
        'description': 'Your data stays secure and private. We never share your personal information.',
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
                  // Glitter particles
                  ...List.generate(30, (i) {
                    final size = 3.5 + math.Random().nextDouble() * 5.5;
                    final x = math.Random().nextDouble() * MediaQuery.of(context).size.width;
                    final y = math.Random().nextDouble() * MediaQuery.of(context).size.height;
                    final colors = isDark
                        ? [
                            const Color(0xFF8CC8FF).withOpacity(0.75),
                            const Color(0xFFB496FF).withOpacity(0.7),
                            const Color(0xFFC8B4FF).withOpacity(0.65),
                          ]
                        : [
                            const Color(0xFFFFFFFF).withOpacity(0.95),
                            const Color(0xFFF0F0FF).withOpacity(0.9),
                            const Color(0xFFFFF0FF).withOpacity(0.85),
                          ];
                    final color = colors[math.Random().nextInt(colors.length)];

                    return GlitterParticle(
                      key: ValueKey(i),
                      size: size,
                      color: color,
                      initialX: x,
                      initialY: y,
                      index: i,
                      scrollY: _scrollY,
                    );
                  }),

                  // Main content
                  AnimatedBuilder(
                    animation: Listenable.merge([_fadeAnim, _slideAnim, _heroScale, _heroOpacity]),
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnim.value,
                        child: ListView(
                          controller: _listScrollController,
                          padding: const EdgeInsets.fromLTRB(20, 60, 20, 120),
                          children: [
                            // Header with theme toggle
                            Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'EmotAI',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white : const Color(0xFF11181C),
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          welcomeText, // ✅ Dynamic welcome with bigger font
                                          style: TextStyle(
                                            fontSize: 18, // 🔼 Increased from 15 to 18
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFFFFFFFF).withOpacity(0.85)
                                                : const Color(0xFF687076),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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

                            const SizedBox(height: 32),

                            // Hero card
                            Transform.scale(
                              scale: _heroScale.value,
                              child: Opacity(
                                opacity: _heroOpacity.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              const Color(0xFFFFFFFF).withOpacity(0.22),
                                              const Color(0xFFFFFFFF).withOpacity(0.06),
                                            ]
                                          : [
                                              const Color(0xFF2C3E50).withOpacity(0.16),
                                              const Color(0xFF2C3E50).withOpacity(0.06),
                                            ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFFFFFFFF).withOpacity(0.22),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 80,
                                          height: 80,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? [
                                                      const Color(0xFF8B7FFF).withOpacity(0.4),
                                                      const Color(0xFF8B7FFF).withOpacity(0.22),
                                                    ]
                                                  : [
                                                      const Color(0xFF0A7EA4).withOpacity(0.28),
                                                      const Color(0xFF0A7EA4).withOpacity(0.16),
                                                    ],
                                            ),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFFFFFFFF).withOpacity(0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.mood_outlined,
                                            size: 42,
                                            color: isDark ? const Color(0xFF8B7FFF) : const Color(0xFF0A7EA4),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Text(
                                          'Welcome to EmotAI',
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.w900,
                                            color: isDark ? Colors.white : const Color(0xFF11181C),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Understand your emotions better with AI-powered facial recognition and real-time analysis',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            height: 1.47,
                                            color: isDark
                                                ? const Color(0xFFFFFFFF).withOpacity(0.9)
                                                : const Color(0xFF687076),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 32),

                            Text(
                              'What We Offer',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: isDark ? Colors.white : const Color(0xFF11181C),
                              ),
                            ),

                            const SizedBox(height: 20),

                            ...features.asMap().entries.map((entry) {
                              final index = entry.key;
                              final feature = entry.value;
                              return FeatureCard(
                                icon: feature['icon'] as IconData,
                                title: feature['title'] as String,
                                description: feature['description'] as String,
                                delay: 500 + index * 150,
                                isDark: isDark,
                              );
                            }).toList(),

                            const SizedBox(height: 24),

                            InkWell(
                              onTap: () {
                                Navigator.pushNamed(context, '/emotion_scan');
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFF8B7FFF),
                                            const Color(0xFFB4A7FF),
                                          ]
                                        : [
                                            const Color(0xFF0A7EA4),
                                            const Color(0xFF3DA5C8),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFFFFFF).withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? const Color(0xFF8B7FFF).withOpacity(0.3)
                                          : const Color(0xFF0A7EA4).withOpacity(0.25),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Get Started',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Icon(
                                        Icons.arrow_forward,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const Navbar(),
          ],
        ),
      ),
    );
  }
}