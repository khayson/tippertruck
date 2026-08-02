import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/routes.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/config_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  final apiClient = ApiClient(baseUrl: baseUrl);
  final authProvider = AuthProvider(apiClient);
  final configProvider = ConfigProvider(apiClient);
  final router = AppRoutes.router(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: configProvider),
      ],
      child: MaterialApp.router(
        title: 'Tipper Truck',
        theme: AppTheme.theme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
      ),
    ),
  );
}
