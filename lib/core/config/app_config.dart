enum AppEnvironment { development, staging, production }

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final bool enableLogging;

  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.enableLogging,
  });

  /// Resolves configuration dynamically at runtime via `--dart-define`
  /// Defaults to Development mode if no variables are supplied.
  factory AppConfig.fromEnvironment() {
    const String envString = String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );
    const String urlString = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8080',
    );

    switch (envString.toLowerCase()) {
      case 'production':
      case 'prod':
        return const AppConfig(
          environment: AppEnvironment.production,
          apiBaseUrl: urlString == 'http://localhost:8080'
              ? 'https://api.cipher-x.org'
              : urlString,
          enableLogging: false,
        );
      case 'staging':
        return const AppConfig(
          environment: AppEnvironment.staging,
          apiBaseUrl: urlString == 'http://localhost:8080'
              ? 'https://staging-api.cipher-x.org'
              : urlString,
          enableLogging: true,
        );
      case 'development':
      case 'dev':
      default:
        return const AppConfig(
          environment: AppEnvironment.development,
          apiBaseUrl: urlString,
          enableLogging: true,
        );
    }
  }

  static const AppConfig dev = AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'http://localhost:8080',
    enableLogging: true,
  );

  static const AppConfig prod = AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://api.cipher-x.org',
    enableLogging: false,
  );
}
