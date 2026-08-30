# Flag Admin Web

Admin Web do Flag Platform — gestão de cadastros pelo organizador (Flutter Web).

## Estrutura

```
├── lib/                    # Código do app
├── web/                    # Assets web (index.html, favicon, etc.)
├── packages/
│   ├── api/                # Cliente HTTP (dio) e serviços da API
│   ├── core/               # Widgets Kickster, tema, utilitários
│   └── domain/             # Models, enums, exceptions
├── pubspec.yaml            # Workspace root
└── .github/workflows/      # CI/CD
```

## Setup

```bash
# Bootstrap (instala dependências de todos os packages)
dart pub global activate melos
melos bootstrap

# Analyze
melos analyze

# Run
flutter run -d chrome
```

## CI

Flutter 3.41.6 pinado no GitHub Actions. Roda `melos analyze` em PRs e pushes para `main`/`develop`.
