import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart' show FlutterQuillLocalizations;
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'widgets/glass_card.dart';
import 'screens/folders_screen.dart';
import 'screens/auth_screen.dart';

Future<void> _initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Cap Firestore cache at 50 MB — smaller cache = faster cold-start open/verify.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024, // 50 MB
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — avoids layout recalculations on rotation
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Kick off Firebase in background — app renders splash immediately
  runApp(SelahNotesApp(firebaseFuture: _initFirebase()));
}

class SelahNotesApp extends StatelessWidget {
  const SelahNotesApp({super.key, required this.firebaseFuture});
  final Future<void> firebaseFuture;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selah Notes',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkGold,
      darkTheme: AppTheme.darkGold,
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: _FastScrollBehavior(),
          child: child!,
        );
      },
      home: _FirebaseGate(firebaseFuture: firebaseFuture),
    );
  }
}

/// Tighter scroll physics — feels snappier on Android
class _FastScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const ClampingScrollPhysics();

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) =>
      child; // Remove glow — saves GPU on every overscroll
}

/// Shows the native-looking splash while Firebase initialises in the background.
/// The first Flutter frame is painted WITHOUT waiting for Firebase at all.
class _FirebaseGate extends StatefulWidget {
  const _FirebaseGate({required this.firebaseFuture});
  final Future<void> firebaseFuture;

  @override
  State<_FirebaseGate> createState() => _FirebaseGateState();
}

class _FirebaseGateState extends State<_FirebaseGate> {
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    widget.firebaseFuture.then((_) {
      if (mounted) setState(() => _ready = true);
    }).catchError((e) {
      if (mounted) setState(() => _error = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Startup error: $_error',
              style: const TextStyle(color: AppColors.danger)),
        ),
      );
    }
    if (!_ready) return const _SplashScreen();
    return const _AuthGate();
  }
}

/// Lightweight splash — paints in one frame, no Firebase dependency.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Use the actual app icon asset — matches the native splash
            Image.asset(
              'assets/app_icon.png',
              width: 96,
              height: 96,
            ),
            const SizedBox(height: 20),
            const Text(
              'Selah Notes',
              style: TextStyle(
                color: AppColors.gold,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: AppColors.gold,
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Listens to Firebase auth state and routes to login or home.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        if (snapshot.hasData) return const FoldersScreen();
        return const AuthScreen();
      },
    );
  }
}
