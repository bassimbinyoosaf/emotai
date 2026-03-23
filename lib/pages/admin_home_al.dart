import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/navbar.dart';
import '../theme/app_theme.dart';

// ================= PARTICLE =================
class AdminParticle extends StatefulWidget {
  final double size;
  final Color color;
  final double x;
  final double y;

  const AdminParticle({
    super.key,
    required this.size,
    required this.color,
    required this.x,
    required this.y,
  });

  @override
  State<AdminParticle> createState() => _AdminParticleState();
}

class _AdminParticleState extends State<AdminParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.repeat(reverse: true);
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
      builder: (_, __) {
        return Positioned(
          left: widget.x,
          top: widget.y,
          child: Opacity(
            opacity: _opacity.value * 0.6,
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

// ================= ADMIN CARD =================
class AdminCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const AdminCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]
              : [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================= ADMIN PAGE =================
class AdminHomeALPage extends StatefulWidget {
  const AdminHomeALPage({super.key});

  @override
  State<AdminHomeALPage> createState() => _AdminHomeALPageState();
}

class _AdminHomeALPageState extends State<AdminHomeALPage>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(_fadeController);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _toggleTheme() {
    context.read<ThemeNotifier>().toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Stack(
        children: [

          // 🌈 BACKGROUND
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
                      ],
              ),
            ),
          ),

          // ✨ PARTICLES
          ...List.generate(20, (i) {
            return AdminParticle(
              size: 4 + math.Random().nextDouble() * 6,
              color: isDark ? Colors.purpleAccent : Colors.blueAccent,
              x: math.Random().nextDouble() * MediaQuery.of(context).size.width,
              y: math.Random().nextDouble() * MediaQuery.of(context).size.height,
            );
          }),

          // 📄 CONTENT
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Colors.purpleAccent, Colors.deepPurple],
                                ),
                              ),
                              child: const Icon(Icons.admin_panel_settings, color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              "Admin Control",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: _toggleTheme,
                          icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Logged in as ${user?.email}",
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // SYSTEM STATUS
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.green.withOpacity(0.15),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 10),
                          Text("System Running Smoothly"),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // ADMIN CARDS
                    const AdminCard(
                      icon: Icons.analytics,
                      title: "User Analytics",
                      subtitle: "View emotional trends & insights",
                    ),

                    const AdminCard(
                      icon: Icons.people,
                      title: "User Management",
                      subtitle: "Control and monitor users",
                    ),

                    const AdminCard(
                      icon: Icons.security,
                      title: "Security Controls",
                      subtitle: "Manage system permissions",
                    ),

                    const SizedBox(height: 20),

                    // 🔥 BUTTON (CORRECT POSITION)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.purpleAccent, Colors.deepPurple],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.all(18),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/admin_dashboard');
                        },
                        child: const Text(
                          "Open Full Analytics Dashboard",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          const Navbar(),
        ],
      ),
    );
  }
}