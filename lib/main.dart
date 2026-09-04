import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'src/app.dart';
import 'src/config/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // URLs reais no browser (/organizations/new em vez de /#/organizations/new).
  usePathUrlStrategy();
  runApp(
    const ProviderScope(
      child: FlagAdminWeb(),
    ),
  );
}
