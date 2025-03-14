// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyCOzZ_3E_tprTHN2MkcGjf4qpbN45oiV7k',
    appId: '1:495824092615:web:b82c15fa7e07f8cac3ade2',
    messagingSenderId: '495824092615',
    projectId: 'unstop-cli',
    authDomain: 'unstop-cli.firebaseapp.com',
    storageBucket: 'unstop-cli.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWnrIaNwLpewcrg2rC0nY7gxF3xZPWIvY',
    appId: '1:495824092615:android:3ddfa4378585a794c3ade2',
    messagingSenderId: '495824092615',
    projectId: 'unstop-cli',
    storageBucket: 'unstop-cli.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCalijqaunl9DWmTVWzw9N6SGo7dr58y-Y',
    appId: '1:495824092615:ios:d08f3745e17c72f1c3ade2',
    messagingSenderId: '495824092615',
    projectId: 'unstop-cli',
    storageBucket: 'unstop-cli.firebasestorage.app',
    iosBundleId: 'com.example.unstopClone',
  );

}