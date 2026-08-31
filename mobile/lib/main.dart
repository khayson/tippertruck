import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_env.dart';
import 'config/app_theme.dart';
import 'config/routes.dart';
import 'core/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/booking_provider.dart';
import 'providers/config_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/driver_orders_provider.dart';
import 'providers/issues_provider.dart';
import 'providers/orders_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(baseUrl: AppEnv.apiBaseUrl);
  final authProvider = AuthProvider(apiClient);
  final configProvider = ConfigProvider(apiClient);
  final bookingProvider = BookingProvider();
  final ordersProvider = OrdersProvider(apiClient);
  final issuesProvider = IssuesProvider(apiClient);
  final driverOrdersProvider = DriverOrdersProvider(apiClient);
  final connectivityProvider = ConnectivityProvider();
  final router = AppRoutes.router(authProvider);

  runApp(
    MultiProvider(
      providers: [
        Provider.value(value: apiClient),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: configProvider),
        ChangeNotifierProvider.value(value: bookingProvider),
        ChangeNotifierProvider.value(value: ordersProvider),
        ChangeNotifierProvider.value(value: issuesProvider),
        ChangeNotifierProvider.value(value: driverOrdersProvider),
        ChangeNotifierProvider.value(value: connectivityProvider),
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
