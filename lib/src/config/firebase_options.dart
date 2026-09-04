import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

/// Configuração do Firebase para o Flag Admin Web.
///
/// Valores podem ser sobrescritos via `--dart-define` no build:
/// - `FIREBASE_API_KEY`
/// - `FIREBASE_AUTH_DOMAIN`
/// - `FIREBASE_PROJECT_ID`
/// - `FIREBASE_STORAGE_BUCKET`
/// - `FIREBASE_MESSAGING_SENDER_ID`
/// - `FIREBASE_APP_ID`
///
/// Os defaults abaixo correspondem ao ambiente `dev` (projeto `flag-platform`).
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Firebase para web.
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_API_KEY',
      defaultValue: 'AIzaSyAj6sQXjsljjIdcesGJ8177x1uvrboXWuY',
    ),
    appId: String.fromEnvironment(
      'FIREBASE_APP_ID',
      defaultValue: '1:890124068903:web:2168cf436ec8e9fd60c602',
    ),
    messagingSenderId: String.fromEnvironment(
      'FIREBASE_MESSAGING_SENDER_ID',
      defaultValue: '890124068903',
    ),
    projectId: String.fromEnvironment(
      'FIREBASE_PROJECT_ID',
      defaultValue: 'flag-platform',
    ),
    storageBucket: String.fromEnvironment(
      'FIREBASE_STORAGE_BUCKET',
      defaultValue: 'flag-platform.firebasestorage.app',
    ),
    authDomain: String.fromEnvironment(
      'FIREBASE_AUTH_DOMAIN',
      defaultValue: 'flag-platform.firebaseapp.com',
    ),
  );
}