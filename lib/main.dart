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
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );
}

void main() {
  // Ensure Flutter engine is ready but don't await Firebase yet —
  // the app renders its first frame immediately, then Firebase initialises
  // in the background. This cuts cold-start blank-screen time significantly.
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
      home: _FirebaseGate(firebaseFuture: firebaseFuture),
    );
  }
}

/// Shows a minimal splash while Firebase initialises, then hands off to
/// the auth gate. The app paints its very first frame without waiting for
/// Firebase, so users see the UI almost instantly.
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
    if (!_ready) {
      // Lightweight splash — no Firebase dependency yet
      return Scaffold(
        backgroundColor: AppColors.background,
        body: GlassBackground(
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          ),
        ),
      );
    }
    return const _AuthGate();
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
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: GlassBackground(
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            ),
          );
        }
        if (snapshot.hasData) return const FoldersScreen();
        return const AuthScreen();
      },
    );
  }
}
