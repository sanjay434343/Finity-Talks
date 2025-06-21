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
    apiKey: 'AIzaSyB-3UoIVsZcWBllUhQ7YqkkH9ttrkeZgno',
    appId: '1:88712486713:web:63677a7affc77a9f3fd2e8',
    messagingSenderId: '88712486713',
    projectId: 'finitytalks',
    authDomain: 'finitytalks.firebaseapp.com',
    storageBucket: 'finitytalks.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB-3UoIVsZcWBllUhQ7YqkkH9ttrkeZgno',
    appId: '1:88712486713:android:63677a7affc77a9f3fd2e8',
    messagingSenderId: '88712486713',
    projectId: 'finitytalks',
    storageBucket: 'finitytalks.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB-3UoIVsZcWBllUhQ7YqkkH9ttrkeZgno',
    appId: '1:88712486713:ios:63677a7affc77a9f3fd2e8',
    messagingSenderId: '88712486713',
    projectId: 'finitytalks',
    storageBucket: 'finitytalks.firebasestorage.app',
    iosBundleId: 'com.app.finitytalks',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB-3UoIVsZcWBllUhQ7YqkkH9ttrkeZgno',
    appId: '1:88712486713:macos:63677a7affc77a9f3fd2e8',
    messagingSenderId: '88712486713',
    projectId: 'finitytalks',
    storageBucket: 'finitytalks.firebasestorage.app',
    iosBundleId: 'com.app.finitytalks',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB-3UoIVsZcWBllUhQ7YqkkH9ttrkeZgno',
    appId: '1:88712486713:windows:63677a7affc77a9f3fd2e8',
    messagingSenderId: '88712486713',
    projectId: 'finitytalks',
    authDomain: 'finitytalks.firebaseapp.com',
    storageBucket: 'finitytalks.firebasestorage.app',
  );
}
