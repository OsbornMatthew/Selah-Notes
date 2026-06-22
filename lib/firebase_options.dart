// File generated manually to match values from google-services.json,
// in place of running `flutterfire configure` (which requires the
// FlutterFire CLI + Firebase CLI installed locally).
//
// If you ever add iOS/web support, run `flutterfire configure` properly
// to regenerate this file with platform-specific blocks.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web — '
        'this app is Android-only.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are only configured for Android in this project.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBmeB14PJcUQmff2G8MRtkEzjxF5F0lHgA',
    appId: '1:263815560706:android:567a5dac703daacfa4711b',
    messagingSenderId: '263815560706',
    projectId: 'selah-notes-ebc6a',
    storageBucket: 'selah-notes-ebc6a.firebasestorage.app',
  );
}
