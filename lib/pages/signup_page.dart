// lib/pages/signup_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';

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
    Future.delayed(
      Duration(milliseconds: (math.Random().nextDouble() * 2000).toInt()),
      () {
        if (mounted) {
          _controller.repeat();
        }
      },
    );
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

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController(); // ✅ STEP 1: Added name controller
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String _nameError = ''; // Optional: could add inline error like others
  String _emailError = '';
  String _passwordError = '';
  String _confirmPasswordError = '';
  bool _isLoading = false;

  bool _verificationSent = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _slideAnim = Tween<double>(begin: -30.0, end: 0.0).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose(); // ✅ Dispose name controller
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateEmail(String email) {
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  bool _validatePassword(String password) {
    return password.length >= 6;
  }

  Future<void> _handleSubmit() async {
    if (_verificationSent) return;

    // Reset errors
    setState(() {
      _nameError = '';
      _emailError = '';
      _passwordError = '';
      _confirmPasswordError = '';
    });

    bool isValid = true;
    final name = _nameController.text.trim(); // ✅ Get name
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // ✅ STEP 2: Validate name
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Email is required');
      isValid = false;
    } else if (!_validateEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email (example@mail.com)');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Password is required');
      isValid = false;
    } else if (!_validatePassword(password)) {
      setState(() => _passwordError = 'Password must be at least 6 characters');
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      setState(() => _confirmPasswordError = 'Please confirm your password');
      isValid = false;
    } else if (password != confirmPassword) {
      setState(() => _confirmPasswordError = "Passwords don't match");
      isValid = false;
    }

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      // 🔥 Create user
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {
        // ✅ STEP 3: SET DISPLAY NAME
        await user.updateDisplayName(name);

        // ✅ Reload to reflect displayName immediately
        await user.reload();

        // ✅ STEP 4: Send email verification (kept as-is)
        await user.sendEmailVerification();

        await FirebaseAuth.instance.signOut();

        if (mounted) {
          setState(() {
            _verificationSent = true;
            _isLoading = false;
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'An unknown error occurred.';
      if (e.code == 'email-already-in-use') {
        message = 'This email is already registered.';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email format.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak (min 6 chars).';
      } else if (e.code == 'operation-not-allowed') {
        message = 'Email/password accounts are not enabled.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleTheme() {
    context.read<ThemeNotifier>().toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
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
              animation: Listenable.merge([_fadeAnim, _slideAnim]),
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 40),
                    children: [
                      // Header
                      Transform.translate(
                        offset: Offset(0, _slideAnim.value),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => mounted
                                  ? Navigator.pushReplacementNamed(
                                      context, '/home')
                                  : null,
                              borderRadius: BorderRadius.circular(25),
                              child: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            const Color(0xFFFFFFFF)
                                                .withOpacity(0.3),
                                            const Color(0xFFFFFFFF)
                                                .withOpacity(0.1),
                                          ]
                                        : [
                                            const Color(0xFF2C3E50)
                                                .withOpacity(0.2),
                                            const Color(0xFF2C3E50)
                                                .withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(0xFF2C3E50)
                                        .withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_back,
                                  size: 24,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Create your account',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFFFFFFFF)
                                              .withOpacity(0.85)
                                          : const Color(0xFF2C3E50)
                                              .withOpacity(0.8),
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
                                            const Color(0xFFFFFFFF)
                                                .withOpacity(0.3),
                                            const Color(0xFFFFFFFF)
                                                .withOpacity(0.1),
                                          ]
                                        : [
                                            const Color(0xFF2C3E50)
                                                .withOpacity(0.2),
                                            const Color(0xFF2C3E50)
                                                .withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(
                                    color: const Color(0xFF2C3E50)
                                        .withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  isDark
                                      ? Icons.wb_sunny
                                      : Icons.nightlight_round,
                                  size: 24,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Sign Up Card
                      Container(
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
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFFFFFFF).withOpacity(0.2),
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [
                                          const Color(0xFF8B7FFF)
                                              .withOpacity(0.35),
                                          const Color(0xFF8B7FFF)
                                              .withOpacity(0.2),
                                        ]
                                      : [
                                          const Color(0xFF6C63FF)
                                              .withOpacity(0.25),
                                          const Color(0xFF6C63FF)
                                              .withOpacity(0.15),
                                        ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFFFFFF)
                                      .withOpacity(0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Icon(
                                Icons.person_add_alt_1_outlined,
                                size: 40,
                                color: isDark
                                    ? const Color(0xFF8B7FFF)
                                    : const Color(0xFF6C63FF),
                              ),
                            ),
                            const SizedBox(height: 32),

                            // ✅ STEP 1: Name Input UI (before Email)
                            TextField(
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                labelStyle: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF2C3E50),
                                  fontWeight: FontWeight.w700,
                                ),
                                prefixIcon: Icon(
                                  Icons.person_outline,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.6)
                                      : const Color(0xFF2C3E50)
                                          .withOpacity(0.6),
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? const Color(0xFF000000).withOpacity(0.2)
                                    : const Color(0xFFFFFFFF).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFFFFFFFF)
                                        .withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: const Color(0xFF8B7FFF),
                                    width: 1.8,
                                  ),
                                ),
                              ),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF2C3E50),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email Input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF000000)
                                            .withOpacity(0.2)
                                        : const Color(0xFFFFFFFF)
                                            .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _emailError.isNotEmpty
                                          ? const Color(0xFFFF4D4D)
                                          : const Color(0xFFFFFFFF)
                                              .withOpacity(0.2),
                                      width: _emailError.isNotEmpty ? 2 : 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your email',
                                      prefixIcon: Icon(
                                        Icons.mail_outline,
                                        size: 20,
                                        color: _emailError.isNotEmpty
                                            ? const Color(0xFFFF4D4D)
                                            : isDark
                                                ? const Color(0xFFFFFFFF)
                                                    .withOpacity(0.6)
                                                : const Color(0xFF2C3E50)
                                                    .withOpacity(0.6),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (_emailError.isNotEmpty) {
                                        setState(() => _emailError = '');
                                      }
                                    },
                                  ),
                                ),
                                if (_emailError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      _emailError,
                                      style: const TextStyle(
                                        color: Color(0xFFFF4D4D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Password Input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF000000)
                                            .withOpacity(0.2)
                                        : const Color(0xFFFFFFFF)
                                            .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _passwordError.isNotEmpty
                                          ? const Color(0xFFFF4D4D)
                                          : const Color(0xFFFFFFFF)
                                              .withOpacity(0.2),
                                      width: _passwordError.isNotEmpty
                                          ? 2
                                          : 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _passwordController,
                                    obscureText: !_showPassword,
                                    autocorrect: false,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Create a password',
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        size: 20,
                                        color: _passwordError.isNotEmpty
                                            ? const Color(0xFFFF4D4D)
                                            : isDark
                                                ? const Color(0xFFFFFFFF)
                                                    .withOpacity(0.6)
                                                : const Color(0xFF2C3E50)
                                                    .withOpacity(0.6),
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(
                                              () => _showPassword = !_showPassword);
                                        },
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: _passwordError.isNotEmpty
                                              ? const Color(0xFFFF4D4D)
                                              : isDark
                                                  ? const Color(0xFFFFFFFF)
                                                      .withOpacity(0.6)
                                                  : const Color(0xFF2C3E50)
                                                      .withOpacity(0.6),
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (_passwordError.isNotEmpty) {
                                        setState(() => _passwordError = '');
                                      }
                                    },
                                  ),
                                ),
                                if (_passwordError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      _passwordError,
                                      style: const TextStyle(
                                        color: Color(0xFFFF4D4D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Confirm Password Input
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Confirm Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF2C3E50),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF000000)
                                            .withOpacity(0.2)
                                        : const Color(0xFFFFFFFF)
                                            .withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _confirmPasswordError.isNotEmpty
                                          ? const Color(0xFFFF4D4D)
                                          : const Color(0xFFFFFFFF)
                                              .withOpacity(0.2),
                                      width: _confirmPasswordError.isNotEmpty
                                          ? 2
                                          : 1.5,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: _confirmPasswordController,
                                    obscureText: !_showConfirmPassword,
                                    autocorrect: false,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF2C3E50),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Re-enter your password',
                                      prefixIcon: Icon(
                                        Icons.lock_clock_outlined,
                                        size: 20,
                                        color: _confirmPasswordError.isNotEmpty
                                            ? const Color(0xFFFF4D4D)
                                            : isDark
                                                ? const Color(0xFFFFFFFF)
                                                    .withOpacity(0.6)
                                                : const Color(0xFF2C3E50)
                                                    .withOpacity(0.6),
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() =>
                                              _showConfirmPassword = !_showConfirmPassword);
                                        },
                                        icon: Icon(
                                          _showConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          size: 20,
                                          color: _confirmPasswordError.isNotEmpty
                                              ? const Color(0xFFFF4D4D)
                                              : isDark
                                                  ? const Color(0xFFFFFFFF)
                                                      .withOpacity(0.6)
                                                  : const Color(0xFF2C3E50)
                                                      .withOpacity(0.6),
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      if (_confirmPasswordError.isNotEmpty) {
                                        setState(() => _confirmPasswordError = '');
                                      }
                                    },
                                  ),
                                ),
                                if (_confirmPasswordError.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6, left: 4),
                                    child: Text(
                                      _confirmPasswordError,
                                      style: const TextStyle(
                                        color: Color(0xFFFF4D4D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            // Submit Button
                            InkWell(
                              onTap: _isLoading || _verificationSent
                                  ? null
                                  : _handleSubmit,
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
                                            const Color(0xFF6C63FF),
                                            const Color(0xFF9D8DFF),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFFFFFFF)
                                        .withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                ),
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _isLoading
                                      ? [
                                          const CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                            strokeWidth: 2,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Creating Account...',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ]
                                      : [
                                          const Text(
                                            'Sign Up',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                ),
                              ),
                            ),
                            if (_verificationSent)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  "Verification link sent to your email.\n"
                                  "Please verify to activate your account.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),
                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account?",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? const Color(0xFFFFFFFF)
                                            .withOpacity(0.8)
                                        : const Color(0xFF2C3E50)
                                            .withOpacity(0.8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                TextButton(
                                  onPressed: () {
                                    if (mounted) {
                                      Navigator.pushReplacementNamed(
                                          context, '/signin');
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Sign In',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF8B7FFF)
                                          : const Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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