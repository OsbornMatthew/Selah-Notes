import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'services/notes_database.dart';
import 'services/firebase_sync_service.dart';
import 'screens/login_screen.dart';
import 'screens/folders_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotesDatabase.init();

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
      home: const _AuthGate(),
    );
  }
}

/// Shows LoginScreen if signed out, FoldersScreen if signed in.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFFD700)),
            ),
          );
        }
        if (snapshot.hasData) {
          // Sync data in background when user is already logged in
          FirebaseSyncService.syncFromFirestore();
          return const FoldersScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
