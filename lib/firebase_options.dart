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
    apiKey: 'AIzaSyB5ppAQrQ1MW2NnUMjq78n0hN5pGgglFJY',
    appId: '1:53674198772:web:6916cbd372177b12dd00a1',
    messagingSenderId: '53674198772',
    projectId: 'fuel-tracker-54dea',
    authDomain: 'fuel-tracker-54dea.firebaseapp.com',
    storageBucket: 'fuel-tracker-54dea.firebasestorage.app',
    measurementId: 'G-P1NSBMKQ5Q',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDRhLMZLHQpVahIATZeyrar5nONbzVfONw',
    appId: '1:53674198772:android:eecc115228651890dd00a1',
    messagingSenderId: '53674198772',
    projectId: 'fuel-tracker-54dea',
    storageBucket: 'fuel-tracker-54dea.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAQN04aDEvvUVHwjgFXXahDntiGzkPxNZY',
    appId: '1:53674198772:ios:deddf7f8b0e20d73dd00a1',
    messagingSenderId: '53674198772',
    projectId: 'fuel-tracker-54dea',
    storageBucket: 'fuel-tracker-54dea.firebasestorage.app',
    iosBundleId: 'com.example.fuelTracker',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAQN04aDEvvUVHwjgFXXahDntiGzkPxNZY',
    appId: '1:53674198772:ios:deddf7f8b0e20d73dd00a1',
    messagingSenderId: '53674198772',
    projectId: 'fuel-tracker-54dea',
    storageBucket: 'fuel-tracker-54dea.firebasestorage.app',
    iosBundleId: 'com.example.fuelTracker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB5ppAQrQ1MW2NnUMjq78n0hN5pGgglFJY',
    appId: '1:53674198772:web:5a87e8a6a2d7234bdd00a1',
    messagingSenderId: '53674198772',
    projectId: 'fuel-tracker-54dea',
    authDomain: 'fuel-tracker-54dea.firebaseapp.com',
    storageBucket: 'fuel-tracker-54dea.firebasestorage.app',
    measurementId: 'G-9EEZQPBPW2',
  );
}
