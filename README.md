# Flag Admin Web

Admin Web do Flag Platform — gestão de cadastros pelo organizador (Flutter Web).

## Estrutura

```
├── lib/                        # Código do app
│   └── src/
│       ├── api/                # Cliente HTTP (dio) e serviços da API REST
│       ├── core/               # Widgets Kickster, tema, utilitários, FirestoreService, config
│       │   └── config/         # Configuração (Firebase, ambiente)
│       ├── domain/             # Models, enums
│       ├── features/           # Modulos por feature (MVVM)
│       │   ├── {feature}/
│       │   │   ├── data/       # datasources (Firestore), repositories
│       │   │   ├── domain/     # regras de negócio da feature
│       │   │   └── presentation/  # viewmodels + screens + widgets
│       ├── providers/          # Riverpod providers
│       └── router/             # GoRouter (app_router)
├── web/                        # Assets web (index.html, favicon, etc.)
├── firebase.json               # Config Firebase CLI (rules Firestore/Storage)
├── firestore.rules             # Regras de segurança Firestore
├── storage.rules               # Regras de segurança Storage
├── pubspec.yaml
└── .github/workflows/          # CI/CD
```

## Setup

```bash
# Dependências
flutter pub get

# Analyze
flutter analyze

# Build web
flutter build web

# Run (dev)
flutter run -d chrome
```

### Configuração Firebase

O projeto Firebase usado é `flag-platform` (projeto Firestore em `us-central1`).
Os valores do `lib/src/core/config/firebase_options.dart` usam **defaults do ambiente dev**
e podem ser sobrescritos via `--dart-define`:

```bash
flutter run -d chrome \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=flag-platform
```

Deploy de rules:

```bash
firebase deploy --only firestore:rules
firebase deploy --only storage
```

## CI

Flutter 3.41.6 pinado no GitHub Actions. Roda `flutter analyze` em PRs e pushes para `main`/`develop`.