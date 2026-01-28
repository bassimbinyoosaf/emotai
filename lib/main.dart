import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'utils/android_toast.dart';

import 'pages/home_page.dart';
import 'pages/about_page.dart';
import 'pages/signin_page.dart';
import 'pages/signup_page.dart';
import 'pages/welcome.dart';
import 'pages/home_al_page.dart';
import 'utils/app_prefs.dart';
import 'pages/emotion_scan_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  FirebaseDatabase.instance.databaseURL =
    "https://emotai123-default-rtdb.asia-southeast1.firebasedatabase.app/";
  

  await AppPrefs.initFirstRun();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..setDark(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

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
    super.dispose();
  }

  /// 🔑 Intercepts Android back gesture globally
  @override
  Future<bool> didPopRoute() async {
    final now = DateTime.now();

    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;

      AndroidToast.show(
        context,
        "Swipe again to exit",
      );

      return true; // block exit
    }

    return false; // allow exit
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp(
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
   AUTH GATE
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

        // ✅ Logged-in users go to HomeAL
        if (user != null && user.emailVerified) {
          return const HomeALPage();
        }

        // ❌ Not logged in → Public Home
        return const HomePage();
      },
    );
  }
}
