import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/navbar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isDeleting = false;

  // ================= PASSWORD DIALOG =================
  Future<String?> _askPassword() async {
    String password = "";
    bool obscure = true;

    return await showDialog<String>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text("Confirm Password"),
            content: TextField(
              obscureText: obscure,
              decoration: InputDecoration(
                hintText: "Enter your password",
                suffixIcon: IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setStateDialog(() {
                      obscure = !obscure;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                password = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, password),
                child: const Text("Confirm"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ================= DELETE ACCOUNT =================
  Future<void> _deleteAccount() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final password = await _askPassword();
      if (password == null || password.isEmpty) return;

      setState(() => _isDeleting = true);

      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      // ✅ STEP 1: RE-AUTHENTICATE
      await user.reauthenticateWithCredential(cred);

      final uid = user.uid;

      // ✅ STEP 2: DELETE FROM REALTIME DATABASE
      final userRef = FirebaseDatabase.instance.ref("users/$uid");
      await userRef.remove();

      debugPrint("✅ User data deleted from Realtime DB");

      // ✅ STEP 3: DELETE AUTH ACCOUNT
      await user.delete();

      debugPrint("✅ User auth deleted");

      if (!mounted) return;

      // ✅ NAVIGATE TO HOME
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
      );

    } catch (e) {
      debugPrint("❌ Delete error: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Wrong password or failed to delete account"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  // ================= CONFIRM DELETE =================
  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
          "Are you sure? This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        Color(0xFF2C3E64),
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

          // 📄 MAIN CONTENT
          SafeArea(
            child: Center(
              child: user == null
                  ? const Text("No user logged in")
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.person, size: 80),
                        const SizedBox(height: 20),

                        Text(
                          user.email ?? "No Email",
                          style: const TextStyle(fontSize: 18),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          "UID: ${user.uid}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),

                        const SizedBox(height: 30),

                        // 🔥 DELETE BUTTON / LOADING
                        _isDeleting
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 12),
                                ),
                                onPressed: _confirmDelete,
                                child: const Text("Delete Account"),
                              ),
                      ],
                    ),
            ),
          ),

          // ✅ NAVBAR
          const Navbar(),
        ],
      ),
    );
  }
}