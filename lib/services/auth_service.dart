import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;
  static String? get uid => _auth.currentUser?.uid;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email & password
  static Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with email & password
  static Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
