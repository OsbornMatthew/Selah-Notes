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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence: notes write instantly to a local cache and
  // sync to the cloud automatically once the device is back online.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const SelahNotesApp());
}

class SelahNotesApp extends StatelessWidget {
  const SelahNotesApp({super.key});

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
      home: const _AuthGate(),
    );
  }
}

/// Listens to Firebase's auth state and shows the login screen or the
/// folders home screen depending on whether someone's signed in.
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
        if (snapshot.hasData) {
          return const FoldersScreen();
        }
        return const AuthScreen();
      },
    );
  }
}
