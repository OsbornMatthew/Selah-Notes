import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static FirebaseAuth get _auth => FirebaseAuth.instance;

  // ── Google Sign-In setup ──────────────────────────────────────────────
  // IMPORTANT (one-time setup, required before this works on a device):
  // 1. Firebase Console → Authentication → Sign-in method → enable "Google".
  // 2. Re-download google-services.json from Project Settings and replace
  //    android/app/google-services.json (it will now contain an oauth_client
  //    entry with a Web client ID).
  // 3. Paste that Web client ID below as _webClientId.
  static const String _webClientId =
      'PASTE_YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInReady = false;

  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInReady) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _googleSignInReady = true;
  }

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  static Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return null; // success
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  /// Returns null on success, or a user-facing error message.
  /// Returns null with no error if the user simply cancelled the picker.
  static Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final authClient = googleUser.authorizationClient;
      final authorization = await authClient.authorizationForScopes(['email', 'profile']) ??
          await authClient.authorizeScopes(['email', 'profile']);

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
        accessToken: authorization.accessToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      return 'Google sign-in failed. Please try again.';
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    } catch (_) {
      return 'Something went wrong with Google sign-in. Please try again.';
    }
  }

  static Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      // Not signed in via Google — safe to ignore.
    }
  }

  static Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyError(e);
    }
  }

  static String _friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a bit and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
