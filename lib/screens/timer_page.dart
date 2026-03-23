import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../main.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {

  Duration selectedDuration = const Duration(seconds: 10);

  Timer? _countdownTimer;
  int _remainingSeconds = 0;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _startReminder(Duration duration) async {

    final totalSeconds = duration.inSeconds;

    setState(() {
      _remainingSeconds = totalSeconds;
    });

    /// UI countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {

        if (_remainingSeconds <= 1) {
          timer.cancel();
        }

        if (mounted) {
          setState(() {
            _remainingSeconds--;
          });
        }

      },
    );

    /// Trigger notification after timer
    Future.delayed(duration, () async {

      await flutterLocalNotificationsPlugin.show(
        999,
        "Time to Talk",
        "Would you like to talk about your feelings now?",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'emotion_channel',
            'Emotion Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );

    });

  }

  String _formatTime(int seconds) {

    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return "${minutes.toString().padLeft(2,'0')}:${secs.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Reminder"),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Remind me to talk later",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 30),

            DropdownButton<int>(
              value: selectedDuration.inSeconds,
              isExpanded: true,
              items: const [

                DropdownMenuItem(
                  value: 10,
                  child: Text("10 seconds"),
                ),

                DropdownMenuItem(
                  value: 20,
                  child: Text("20 seconds"),
                ),

                DropdownMenuItem(
                  value: 30,
                  child: Text("30 seconds"),
                ),

              ],
              onChanged: (value) {
                setState(() {
                  selectedDuration = Duration(seconds: value!);
                });
              },
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await _startReminder(selectedDuration);
                },
                child: const Text("Set Reminder"),
              ),
            ),

            const SizedBox(height: 25),

            if (_remainingSeconds > 0)
              Column(
                children: [

                  const Text(
                    "Reminder in",
                    style: TextStyle(fontSize: 14),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                ],
              ),

          ],
        ),
      ),
    );
  }
}