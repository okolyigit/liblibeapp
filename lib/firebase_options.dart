// File generated manually based on Firebase Console config.
// For additional platforms (Android/iOS), add platform-specific configs.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDxEMoXPXS0JKgYBsnFLi6OesJ70wAAnU8',
    appId: '1:676632601870:web:ef9ed0a1b62e3520e1635f',
    messagingSenderId: '676632601870',
    projectId: 'liblibe-aef1b',
    authDomain: 'liblibe-aef1b.firebaseapp.com',
    storageBucket: 'liblibe-aef1b.firebasestorage.app',
    measurementId: 'G-3WEZZE341T',
  );

  // Android - From google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAixy31n4McQ2szn8tkuXY6RMFGX69mseY',
    appId: '1:676632601870:android:ac3fe67ade22753be1635f',
    messagingSenderId: '676632601870',
    projectId: 'liblibe-aef1b',
    storageBucket: 'liblibe-aef1b.firebasestorage.app',
  );

  // iOS - Add your iOS app in Firebase Console to get these values
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDxEMoXPXS0JKgYBsnFLi6OesJ70wAAnU8',
    appId:
        '1:676632601870:web:ef9ed0a1b62e3520e1635f', // Replace with iOS appId
    messagingSenderId: '676632601870',
    projectId: 'liblibe-aef1b',
    storageBucket: 'liblibe-aef1b.firebasestorage.app',
    iosBundleId: 'com.example.liblibeapp',
  );

  // macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDxEMoXPXS0JKgYBsnFLi6OesJ70wAAnU8',
    appId: '1:676632601870:web:ef9ed0a1b62e3520e1635f',
    messagingSenderId: '676632601870',
    projectId: 'liblibe-aef1b',
    storageBucket: 'liblibe-aef1b.firebasestorage.app',
    iosBundleId: 'com.example.liblibeapp',
  );

  // Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDxEMoXPXS0JKgYBsnFLi6OesJ70wAAnU8',
    appId: '1:676632601870:web:ef9ed0a1b62e3520e1635f',
    messagingSenderId: '676632601870',
    projectId: 'liblibe-aef1b',
    authDomain: 'liblibe-aef1b.firebaseapp.com',
    storageBucket: 'liblibe-aef1b.firebasestorage.app',
    measurementId: 'G-3WEZZE341T',
  );
}
