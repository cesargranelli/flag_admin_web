import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;

/// Configuração do Firebase para o Flag Admin Web.
///
/// Valores injetados via `--dart-define` no build:
/// - `FIREBASE_API_KEY`
/// - `FIREBASE_AUTH_DOMAIN`
/// - `FIREBASE_PROJECT_ID`
/// - `FIREBASE_STORAGE_BUCKET`
/// - `FIREBASE_MESSAGING_SENDER_ID`
/// - `FIREBASE_APP_ID`
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Firebase para web.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId:
        String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );
}
