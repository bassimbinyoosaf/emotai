import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../widgets/navbar.dart';

// ================= PAGE =================
class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {

  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child("users");

  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  int totalUsers = 0;
  int adminCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // ================= FETCH USERS =================
  Future<void> _fetchUsers() async {
    
    try {
      final snapshot = await _dbRef.get();

      if (!snapshot.exists || snapshot.value == null) {
        setState(() {
          users = [];
          isLoading = false;
        });
        return;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;

      final List<Map<String, dynamic>> loadedUsers = [];

      data.forEach((uid, value) {
        if (value == null) return;

        final userMap = Map<String, dynamic>.from(value);

        // ✅ PROFILE
        final profile = userMap["profile"] != null
            ? Map<String, dynamic>.from(userMap["profile"])
            : {};

        final name = profile["username"] ?? "No Name";
        final email = profile["email"] ?? "No Email";

        // ✅ EMOTIONS → GET LATEST
        String latestEmotion = "Unknown";

        if (userMap["emotions"] != null) {
          final emotions =
              Map<String, dynamic>.from(userMap["emotions"]);

          int latestTime = 0;

          emotions.forEach((key, value) {
            final emo = Map<String, dynamic>.from(value);

            final timestamp = emo["timestamp"] ?? 0;

            if (timestamp > latestTime) {
              latestTime = timestamp;
              latestEmotion = emo["emotion_type"] ?? "Unknown";
            }    
          });
        }

        loadedUsers.add({
          "uid": uid.toString(),
          "name": name,
          "email": email,
          "createdAt": "N/A", // you don’t have this yet
          "emotion": latestEmotion,
          "role": "user", // optional (you don’t store role yet)
        });
      });

      setState(() {
        users = loadedUsers;
        totalUsers = loadedUsers.length;
        adminCount = 0; // since no role stored
        isLoading = false;
      });

    } catch (e) {
      debugPrint("🔥 Error fetching users: $e");
      setState(() => isLoading = false);
      
    }
    
  }

  // ================= DELETE USER =================
  Future<void> _deleteUser(String uid) async {
    await _dbRef.child(uid).remove();
    _fetchUsers();
  }

  // ================= MAKE ADMIN =================
  Future<void> _makeAdmin(String uid) async {
    await _dbRef.child(uid).child("profile").update({"role": "admin"});
    _fetchUsers();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          ...List.generate(10, (i) {
            return Positioned(
              left: math.Random().nextDouble() * MediaQuery.of(context).size.width,
              top: math.Random().nextDouble() * MediaQuery.of(context).size.height,
              child: Container(
                width: 4 + math.Random().nextDouble() * 6,
                height: 4 + math.Random().nextDouble() * 6,
                decoration: const BoxDecoration(
                  color: Colors.purpleAccent,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),

          // 📄 CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // HEADER
                        const Text(
                          "Admin Dashboard",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ================= STATS CARDS =================
                        Row(
                          children: [
                            _buildStatCard("Users", totalUsers.toString()),
                            const SizedBox(width: 10),
                            _buildStatCard("Admins", adminCount.toString()),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ================= USER LIST =================
                        Expanded(
                          child: ListView.builder(
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white.withOpacity(0.1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // NAME + ROLE
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          user["name"],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          user["role"],
                                          style: TextStyle(
                                            color: user["role"] == "admin"
                                                ? Colors.greenAccent
                                                : Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      user["email"],
                                      style: const TextStyle(color: Colors.white70),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Created: ${user["createdAt"]}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    Text(
                                      "Last Emotion: ${user["emotion"]}",
                                      style: const TextStyle(
                                        color: Colors.purpleAccent,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // ACTION BUTTONS
                                    Row(
                                      children: [
                                        ElevatedButton(
                                          onPressed: () => _makeAdmin(user["uid"]),
                                          child: const Text("Make Admin"),
                                        ),
                                        const SizedBox(width: 10),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () => _deleteUser(user["uid"]),
                                          child: const Text("Delete"),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const Navbar(),
        ],
      ),
    );
  }

  // ================= STAT CARD =================
  Widget _buildStatCard(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}