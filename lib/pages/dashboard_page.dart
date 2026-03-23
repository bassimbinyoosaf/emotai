import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/navbar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, int> emotionCount = {};
  Map<String, int> dailyEmotionCount = {};
  bool loading = true;

  String selectedGraph = "trend";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseDatabase.instance
        .ref()
        .child("users")
        .child(user.uid)
        .child("emotions")
        .get();

    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);

      Map<String, int> temp = {};
      Map<String, int> dailyTemp = {};

      for (var item in data.values) {
        final emotion = item["emotion_type"];
        final timestamp = item["timestamp"];

        if (emotion != null) {
          temp[emotion] = (temp[emotion] ?? 0) + 1;
        }

        if (timestamp != null) {
          final d =
              DateTime.fromMillisecondsSinceEpoch(timestamp);
          final key = "${d.day}/${d.month}";
          dailyTemp[key] = (dailyTemp[key] ?? 0) + 1;
        }
      }

      setState(() {
        emotionCount = temp;
        dailyEmotionCount = dailyTemp;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  // ================= LOGIC =================

  String topEmotion() {
    if (emotionCount.isEmpty) return "None";
    return emotionCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int totalScans() {
    return emotionCount.values.fold(0, (a, b) => a + b);
  }

  String trend() {
    if (dailyEmotionCount.length < 2) return "Stable";
    final v = dailyEmotionCount.values.toList();
    if (v.last > v.first) return "Improving 📈";
    if (v.last < v.first) return "Declining 📉";
    return "Stable ➖";
  }

  // ✅ FIXED SUMMARY
  String summary() {
    if (emotionCount.isEmpty) {
      return "No emotion data yet. Start scanning to see your mood insights.";
    }

    final top = topEmotion();

    if (top.contains("sad")) return "You've been feeling low.";
    if (top.contains("happy")) return "You're doing great!";
    if (top.contains("anger")) return "You seem stressed.";

    return "Your mood looks stable.";
  }

  // ✅ FIXED SUGGESTION
  String suggestion() {
    if (emotionCount.isEmpty) {
      return "Capture your first emotion to get personalized suggestions.";
    }

    final top = topEmotion();

    if (top.contains("sad")) return "Try music or a short walk.";
    if (top.contains("anger")) return "Take a break and breathe.";
    if (top.contains("happy")) return "Keep enjoying your day!";

    return "Do something you like.";
  }

  // ================= GRAPH =================

  List<FlSpot> lineData() {
    int i = 0;
    return dailyEmotionCount.entries.map((e) {
      final s = FlSpot(i.toDouble(), e.value.toDouble());
      i++;
      return s;
    }).toList();
  }

  List<BarChartGroupData> barData() {
    int i = 0;
    return emotionCount.entries.map((e) {
      final g = BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: e.value.toDouble())],
      );
      i++;
      return g;
    }).toList();
  }

  // ================= TOGGLE =================

  Widget _toggleButton(String type, String label) {
    final isSelected = selectedGraph == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedGraph = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.blueAccent : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [Color(0xFF0F2027), Color(0xFF203A43)]
                    : [Color(0xFFeef2ff), Color(0xFFe0f7fa)],
              ),
            ),
          ),

          SafeArea(
            child: loading
                ? Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [

                        // 🔥 GRAPH HEADER
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Your Activity",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(20),
                                color: Colors.white.withOpacity(0.1),
                              ),
                              child: Row(
                                children: [
                                  _toggleButton("trend", "Trend"),
                                  _toggleButton(
                                      "distribution", "Distribution"),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        // 🔥 GRAPH / EMPTY STATE
                        Container(
                          height: 240,
                          padding: EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(20),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: emotionCount.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.insights,
                                          size: 50,
                                          color: Colors.grey),
                                      SizedBox(height: 10),
                                      Text("No data yet"),
                                      Text(
                                          "Start scanning to see insights"),
                                    ],
                                  ),
                                )
                              : selectedGraph == "trend"
                                  ? LineChart(
                                      LineChartData(
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: lineData(),
                                            isCurved: true,
                                            dotData: FlDotData(show: true),
                                          ),
                                        ],
                                      ),
                                    )
                                  : BarChart(
                                      BarChartData(
                                          barGroups: barData()),
                                    ),
                        ),

                        SizedBox(height: 25),

                        // 🔥 SUMMARY
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(20),
                            color: Colors.blueAccent,
                          ),
                          child: Text(
                            summary(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),

                        SizedBox(height: 20),

                        // 🔥 STATS
                        Row(
                          children: [
                            _card("Total", totalScans().toString()),
                            _card("Top", topEmotion()),
                          ],
                        ),

                        SizedBox(height: 10),

                        Row(
                          children: [
                            _card("Trend", trend()),
                            _card("Days",
                                dailyEmotionCount.length.toString()),
                          ],
                        ),

                        SizedBox(height: 20),

                        // 🔥 SUGGESTION
                        Text("Suggestion",
                            style: TextStyle(
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 6),
                        Text(suggestion()),

                        SizedBox(height: 80),
                      ],
                    ),
                  ),
          ),

          const Navbar(),
        ],
      ),
    );
  }

  Widget _card(String title, String value) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 5),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.15),
        ),
        child: Column(
          children: [
            Text(title),
            SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}