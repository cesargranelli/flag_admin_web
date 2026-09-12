/// Base/core providers for the Flag Admin Web application.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flag_admin_web/data/session/session_manager.dart';
import 'package:flag_admin_web/data/api/api_client.dart';

/// Gerenciador de sessão do Admin Web (persiste dados de sessão Firebase/JWT).
final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(),
);

/// Instância do Firebase Storage.
final firebaseStorageProvider = Provider<FirebaseStorage>(
  (ref) => FirebaseStorage.instance,
);

/// Cliente HTTP da API REST com o JWT do backend e Firebase ID Token injetados.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(sessionManager: ref.watch(sessionManagerProvider)),
);
