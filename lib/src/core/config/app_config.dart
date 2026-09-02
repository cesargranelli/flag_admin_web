/// Configuração de ambiente do Flag Platform.
///
/// Valores injetados via `--dart-define` no build:
/// - `API_BASE_URL`: base URL da API REST (default: `http://localhost:8080`)
/// - `ENVIRONMENT`: nome do ambiente (default: `dev`)
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String environment = String.fromEnvironment(
    'ENVITY',
    defaultValue: 'dev',
  );

  /// Converte URL relativa (ex.: /api/v1/uploads/arquivo.jpg) para absoluta,
  /// prependendo [apiBaseUrl]. URLs já absolutas são retornadas sem alteração.
  /// Necessário porque o Flutter Web roda em porta diferente da API.
  static String resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('/')) return '$apiBaseUrl$url';
    return url;
  }

  const AppConfig._();
}
