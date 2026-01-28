// lib/widgets/navbar.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ Required for signOut
import '../utils/app_prefs.dart';

class NavItem {
  final String name;
  final IconData icon;
  final String route;

  const NavItem({
    required this.name,
    required this.icon,
    required this.route,
  });
}

class Navbar extends StatefulWidget {
  const Navbar({Key? key}) : super(key: key);

  @override
  State<Navbar> createState() => _NavbarState();
}

class _NavbarState extends State<Navbar> with SingleTickerProviderStateMixin {
  int? _hoveredIndex;
  int _activeIndex = 0;
  late AnimationController _transitionController;
  late Animation<double> _transitionAnimation;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _transitionAnimation = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _transitionController.dispose();
    super.dispose();
  }

  List<NavItem> get _currentNavItems {
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && user.emailVerified;

    if (isLoggedIn) {
      return [
        NavItem(name: 'Home', icon: Icons.home, route: '/home_al'),
        NavItem(name: 'About', icon: Icons.info_outline, route: '/about'),
        NavItem(name: 'Sign Out', icon: Icons.logout, route: '/signout'),
      ];
    } else {
      return [
        NavItem(name: 'Home', icon: Icons.home, route: '/home'),
        NavItem(name: 'About', icon: Icons.info_outline, route: '/about'),
        NavItem(name: 'Sign In', icon: Icons.login_outlined, route: '/signin'),
      ];
    }
  }

  bool _isActive(String route, String currentRoute) {
    final normalizedRoute = route.replaceAll(RegExp(r'/$'), '');
    final normalizedCurrent = currentRoute.replaceAll(RegExp(r'/$'), '');

    // ✅ FIX 2: Treat both /home and /home_al as root home routes
    if (normalizedRoute == '/home' || normalizedRoute == '/home_al') {
      if (normalizedCurrent == '' ||
          normalizedCurrent == '/' ||
          normalizedCurrent == '/home' ||
          normalizedCurrent == '/home_al') {
        return true;
      }
    }

    return normalizedCurrent == normalizedRoute ||
        normalizedCurrent.startsWith('$normalizedRoute/');
  }

  bool _shouldHideNavbar(String currentRoute) {
    final normalized = currentRoute.replaceAll(RegExp(r'/$'), '');
    return normalized == '/signin' ||
        normalized == '/signup';
  }

  void _updateActiveIndex(String currentRoute, List<NavItem> items) {
    final newIndex = items.indexWhere((item) => _isActive(item.route, currentRoute));
    if (newIndex != -1 && newIndex != _activeIndex) {
      setState(() {
        _activeIndex = newIndex;
      });
      _transitionController.forward(from: 0);
    }
  }

  // ✅ UPDATED: Handle navigation with special logic for /signout
  void _handleNavigation(BuildContext context, NavItem item) {
    if (item.route == '/signout') {
      // 🔥 REPLACE onTap content ONLY as requested
      () async {
        await FirebaseAuth.instance.signOut();

        await AppPrefs.clearLocalState(); // ✅ Clears saved flags

        if (!context.mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }();
    } else {
      Navigator.pushReplacementNamed(context, item.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modalRoute = ModalRoute.of(context);
    final displayNavItems = _currentNavItems;

    // ✅ FIX 1: Force correct fallback route based on auth state
    final user = FirebaseAuth.instance.currentUser;
    final isLoggedIn = user != null && user.emailVerified;

    // If ModalRoute is null (e.g., first frame), use auth-aware fallback
    final currentRoute = modalRoute?.settings.name ??
        (isLoggedIn ? '/home_al' : '/home');

    _updateActiveIndex(currentRoute, displayNavItems);

    if (_shouldHideNavbar(currentRoute)) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final navbarWidth = screenWidth - 40;
    final clampedWidth = navbarWidth > 360 ? 360.0 : navbarWidth;

    final accentColor = isDark ? const Color(0xFF8B7FFF) : const Color(0xFF6C63FF);
    final textSecondary = Theme.of(context).colorScheme.onSurface.withOpacity(0.55);

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          width: clampedWidth,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: accentColor.withOpacity(isDark ? 0.1 : 0.05),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isDark ? 80 : 100,
                sigmaY: isDark ? 80 : 100,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color(0xFF1A1A2E).withOpacity(0.95),
                            const Color(0xFF16213E).withOpacity(0.9),
                          ]
                        : [
                            Colors.white.withOpacity(0.98),
                            const Color(0xFFFAFAFA).withOpacity(0.92),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: displayNavItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final active = _isActive(item.route, currentRoute);
                      final isHovered = _hoveredIndex == index;

                      return Expanded(
                        child: Center(
                          child: _NavItemWidget(
                            item: item,
                            active: active,
                            isHovered: isHovered,
                            isDark: isDark,
                            accentColor: accentColor,
                            textSecondary: textSecondary,
                            transitionProgress: _transitionAnimation.value,
                            onTap: () => _handleNavigation(context, item),
                            onHoverStart: () => setState(() => _hoveredIndex = index),
                            onHoverEnd: () => setState(() => _hoveredIndex = null),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ _NavItemWidget remains COMPLETELY UNCHANGED
class _NavItemWidget extends StatefulWidget {
  final NavItem item;
  final bool active;
  final bool isHovered;
  final bool isDark;
  final Color accentColor;
  final Color textSecondary;
  final double transitionProgress;
  final VoidCallback onTap;
  final VoidCallback onHoverStart;
  final VoidCallback onHoverEnd;

  const _NavItemWidget({
    required this.item,
    required this.active,
    required this.isHovered,
    required this.isDark,
    required this.accentColor,
    required this.textSecondary,
    required this.transitionProgress,
    required this.onTap,
    required this.onHoverStart,
    required this.onHoverEnd,
  });

  @override
  State<_NavItemWidget> createState() => _NavItemWidgetState();
}

class _NavItemWidgetState extends State<_NavItemWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;
  late AnimationController _rotateController;
  late Animation<double> _rotateAnimation;
  bool _wasActive = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.75)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.75, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
    ]).animate(_scaleController);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _rotateAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.15)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.15, end: 0.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_rotateController);

    _wasActive = widget.active;
  }

  @override
  void didUpdateWidget(_NavItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_wasActive) {
      _scaleController.forward(from: 0);
      _rotateController.forward(from: 0);
      _wasActive = true;
    } else if (!widget.active && _wasActive) {
      _wasActive = false;
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => widget.onHoverStart(),
      onTapUp: (_) => widget.onHoverEnd(),
      onTapCancel: () => widget.onHoverEnd(),
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rotateAnimation]),
        builder: (context, child) {
          final scale = widget.active ? _scaleAnimation.value : 1.0;
          final rotate = widget.active ? _rotateAnimation.value : 0.0;
          final baseOpacity = widget.active
              ? (1.0 - (widget.transitionProgress * 0.4)).clamp(0.7, 1.0)
              : (widget.transitionProgress * 1.2).clamp(0.0, 1.0);

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: rotate,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                decoration: widget.active
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: widget.isDark
                              ? [
                                  const Color(0xFF8B7FFF).withOpacity(0.7 * baseOpacity),
                                  const Color(0xFF6C63FF).withOpacity(0.5 * baseOpacity),
                                ]
                              : [
                                  const Color(0xFF6C63FF).withOpacity(0.55 * baseOpacity),
                                  const Color(0xFF8B7FFF).withOpacity(0.4 * baseOpacity),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: widget.accentColor.withOpacity(0.7 * baseOpacity),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.accentColor.withOpacity(0.25 * baseOpacity),
                            blurRadius: 12 * baseOpacity,
                            spreadRadius: 2 * baseOpacity,
                          ),
                        ],
                      )
                    : widget.isHovered
                        ? BoxDecoration(
                            color: widget.isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(50),
                          )
                        : null,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                alignment: Alignment.center,
                child: Icon(
                  widget.item.icon,
                  size: 24,
                  color: widget.active
                      ? Colors.white.withOpacity(baseOpacity)
                      : (widget.isHovered
                          ? widget.textSecondary.withOpacity(0.85)
                          : widget.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}