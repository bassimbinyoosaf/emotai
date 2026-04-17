import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_messaging/firebase_messaging.dart';

// ✅ NEW IMPORTS FOR ACTIVE STATUS TRACKING
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'screens/profile_page.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'utils/android_toast.dart';
import 'utils/app_prefs.dart';

import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/welcome.dart';
import 'pages/home_al_page.dart';
import 'pages/emotion_scan_page.dart';
import 'screens/chat_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/admin_home_al.dart';
import 'pages/admin_dashboard_page.dart';
import 'services/role_service.dart';

// 🔔 Global notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔑 Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// 🔗 API Base URL
const String baseUrl = "http://192.168.1.4:3000";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// 🔥 Firebase Init
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Foreground notification received");

    if (message.notification != null) {
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification!.title,
        message.notification!.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'emotion_channel',
            'Emotion Reminders',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    }
  });

  FirebaseDatabase.instance.databaseURL =
      "https://emotai123-default-rtdb.asia-southeast1.firebasedatabase.app/";

  await FirebaseMessaging.instance.requestPermission();

  /// 🌍 Timezone Init
  tzdata.initializeTimeZones();
  tz.setLocalLocation(tz.local);

  /// 🔔 Notification Channel
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'emotion_channel',
    'Emotion Reminders',
    description: 'Reminder to talk about emotions',
    importance: Importance.max,
  );

  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidInitSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => const ChatPage(detectedEmotion: "Reminder"),
        ),
      );
    },
  );

  final androidPlugin = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(channel);
    await androidPlugin.requestNotificationsPermission();
  }

  await AppPrefs.initFirstRun();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..setDark(),
      child: const MyApp(),
    ),
  );
}

// ✅ STEP 2: MyApp converted to StatefulWidget
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

// ✅ STEP 2: New _MyAppState with WidgetsBindingObserver for lifecycle tracking
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _lastBackPressed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    updateUserActiveStatus(false); // app closed / backgrounded
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App is in foreground and interactive
      updateUserActiveStatus(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App is in background or being terminated
      updateUserActiveStatus(false);
    }
  }

  @override
  Future<bool> didPopRoute() async {
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      AndroidToast.show(context, "Swipe again to exit");

      return true;
    }

    return false;
  }

  /// 🔥 Updates user active status on backend
  Future<void> updateUserActiveStatus(bool isActive) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await http.post(
        Uri.parse('$baseUrl/user-active'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'isActive': isActive}),
      );

      print('GLOBAL ACTIVE: $isActive');
    } catch (e) {
      print('ACTIVE ERROR: $e');
      // Optional: Add retry logic or local queue for failed requests
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,

      routes: {
        '/home': (context) => const HomePage(),
        '/about': (context) => const AboutPage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/welcome': (context) => const WelcomePage(),
        '/home_al': (context) => const HomeALPage(),
        '/emotion_scan': (context) => const EmotionScanPage(),
        '/profile': (context) => const ProfilePage(),
        '/dashboard': (context) => const DashboardPage(),
        '/admin_home': (context) => const AdminHomeALPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
      },

      initialRoute: '/',

      onGenerateRoute: (settings) {
        if (settings.name == '/') {
          return MaterialPageRoute(
            settings: const RouteSettings(name: '/'),
            builder: (_) => const AuthGate(),
          );
        }
        return null;
      },
    );
  }
}

/* =========================
   AUTH GATE (FIXED)
   ========================= */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        // ✅ USER LOGGED IN
        if (user != null && user.emailVerified) {
          final role = RoleService.getRole(user.email ?? "");

          // 🔥 ADMIN
          if (role == UserRole.admin) {
            return const AdminHomeALPage();
          }

          // 👤 NORMAL USER
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final userId = FirebaseAuth.instance.currentUser?.uid;

            if (userId != null) {
              http.post(
                Uri.parse('$baseUrl/user-active'),
                headers: {'Content-Type': 'application/json'},
                body: jsonEncode({'userId': userId, 'isActive': true}),
              );
            }
          });

          return const HomeALPage();
        }

        // 🚪 NOT LOGGED IN
        return const HomePage();
      },
    );
  }
}
