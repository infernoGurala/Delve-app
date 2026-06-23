import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // These keys are extracted from android/app/google-services.json
    return const FirebaseOptions(
      apiKey: 'AIzaSyBxcJdNX_EdjKd0CSNF_ECu6JIzjABWuqY',
      appId: '1:77888789578:android:0fc2ad7ae4856310181ab3',
      messagingSenderId: '77888789578',
      projectId: 'delve-app-bb660',
      storageBucket: 'delve-app-bb660.firebasestorage.app',
    );
  }
}
