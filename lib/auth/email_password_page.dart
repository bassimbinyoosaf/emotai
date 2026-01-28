import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../pages/welcome.dart';

/* =========================
   SIGN IN / SIGN UP PAGE
   ========================= */

class EmailPasswordPage extends StatefulWidget {
  const EmailPasswordPage({super.key});

  @override
  State<EmailPasswordPage> createState() => _EmailPasswordPageState();
}

class _EmailPasswordPageState extends State<EmailPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<void> checkUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email and password are required")),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    try {
      final userCredential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null && user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomePage()),
        );
      } else {
        await user?.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please verify your email. Verification link has been sent.",
            ),
          ),
        );

        await auth.signOut();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' ||
          e.code == 'invalid-credential' ||
          e.code == 'invalid-login-credentials') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpPage(
              email: email,
              password: password,
            ),
          ),
        );
      } else if (e.code == 'wrong-password') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Wrong password")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? "Authentication error")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign In / Sign Up")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "New user? We’ll create an account automatically.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: checkUser,
              child: const Text("Continue"),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   EMAIL VERIFICATION PAGE
   ========================= */

class OtpPage extends StatefulWidget {
  final String email;
  final String password;

  const OtpPage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    createUserAndSendVerification();
  }

  Future<void> createUserAndSendVerification() async {
    try {
      final userCredential =
          await auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: widget.password,
      );

      await userCredential.user!.sendEmailVerification();
      setState(() => loading = false);
    } on FirebaseAuthException catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Error")),
      );
    }
  }

  Future<void> checkVerificationManually() async {
    await auth.currentUser!.reload();
    final user = auth.currentUser;

    if (user != null && user.emailVerified) {
      await auth.signOut();
      Navigator.pop(context); // back to login
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email not verified yet")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Verification link sent.\nPlease check your email.",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: checkVerificationManually,
                    child: const Text("I’ve verified my email"),
                  ),
                ],
              ),
      ),
    );
  }
}
