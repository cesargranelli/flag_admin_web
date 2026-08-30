# Flag Admin Web

Admin Web do Flag Platform — gestão de cadastros pelo organizador (Flutter Web).

## Estrutura

```
├── lib/
│   ├── main.dart             # Entry point
│   ├── src/                  # Código do app (telas, router, providers, widgets)
│   ├── api/                  # Cliente HTTP (dio) e serviços da API
│   ├── core/                 # Widgets Kickster, tema, configuração, sessão
│   └── domain/               # Models, enums
├── web/                      # Assets web (index.html, favicon, etc.)
├── pubspec.yaml
└── .github/workflows/        # CI/CD
```

## Setup

```bash
flutter pub get
flutter run -d chrome
```

## CI

Flutter 3.41.6 pinado no GitHub Actions. Roda `flutter analyze` em PRs e pushes para `main`/`develop`.
