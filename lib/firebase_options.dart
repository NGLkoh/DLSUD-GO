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
    apiKey: 'AIzaSyAVRgAQrWThx3FdoBwZR2Err6EgMYa_qFI',
    appId: '1:473396823764:web:591a640b4f5f0223111d41',
    messagingSenderId: '473396823764',
    projectId: 'dlsud-go',
    authDomain: 'dlsud-go.firebaseapp.com',
    storageBucket: 'dlsud-go.firebasestorage.app',
    measurementId: 'G-FVE5QWT1ZK',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAQjKMS2m-uQEUacpE9dq10jQRVSbk2OyI',
    appId: '1:473396823764:android:70ba2278f99ebad2111d41',
    messagingSenderId: '473396823764',
    projectId: 'dlsud-go',
    storageBucket: 'dlsud-go.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBoPFgm9sb1oSk0ATQ0AtZmqR7bMljGe0M',
    appId: '1:473396823764:ios:863142926f3e1f37111d41',
    messagingSenderId: '473396823764',
    projectId: 'dlsud-go',
    storageBucket: 'dlsud-go.firebasestorage.app',
    iosBundleId: 'com.example.dlsudGo',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBoPFgm9sb1oSk0ATQ0AtZmqR7bMljGe0M',
    appId: '1:473396823764:ios:863142926f3e1f37111d41',
    messagingSenderId: '473396823764',
    projectId: 'dlsud-go',
    storageBucket: 'dlsud-go.firebasestorage.app',
    iosBundleId: 'com.example.dlsudGo',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAVRgAQrWThx3FdoBwZR2Err6EgMYa_qFI',
    appId: '1:473396823764:web:e152680f47f184d9111d41',
    messagingSenderId: '473396823764',
    projectId: 'dlsud-go',
    authDomain: 'dlsud-go.firebaseapp.com',
    storageBucket: 'dlsud-go.firebasestorage.app',
    measurementId: 'G-ZQ843HXFQP',
  );
}
