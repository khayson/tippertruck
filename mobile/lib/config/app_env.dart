/// Compile-time / shared environment for API and related URLs.
class AppEnv {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Filament admin panel on the same host as the API (…/admin).
  static String get adminPortalUrl {
    final uri = Uri.parse(apiBaseUrl);
    final port = uri.hasPort ? ':${uri.port}' : '';
    final origin = '${uri.scheme}://${uri.host}$port';
    return '$origin/admin';
  }
}
