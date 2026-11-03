enum AppEnvironment {
  dev,
  staging,
  prod,
}

extension AppEnvironmentExtension on AppEnvironment {
  String get name {
    switch (this) {
      case AppEnvironment.dev:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.prod:
        return 'Production';
    }
  }

  bool get isProduction => this == AppEnvironment.prod;
  bool get isDevelopment => this == AppEnvironment.dev;
}
