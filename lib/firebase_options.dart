import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with [Firebase.initializeApp].
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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForCompilingOnly_abcdef',
    appId: '1:1234567890:web:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'atrialfa-1dc01',
    authDomain: 'atrialfa-1dc01.firebaseapp.com',
    storageBucket: 'atrialfa-1dc01.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForCompilingOnly_abcdef',
    appId: '1:1234567890:android:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'atrialfa-1dc01',
    storageBucket: 'atrialfa-1dc01.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyFakeKeyForCompilingOnly_abcdef',
    appId: '1:1234567890:ios:abcdef1234567890',
    messagingSenderId: '1234567890',
    projectId: 'atrialfa-1dc01',
    storageBucket: 'atrialfa-1dc01.appspot.com',
    iosBundleId: 'com.atri.pdf',
  );
}
