import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/booking/delivery_location_screen.dart';
import '../screens/booking/order_summary_screen.dart';
import '../screens/booking/order_success_screen.dart';
import '../screens/booking/payment_screen.dart';
import '../screens/booking/truck_type_screen.dart';
import '../screens/chatbot/chatbot_screen.dart';
import '../screens/driver/driver_home_screen.dart';
import '../screens/driver/driver_order_detail_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/issues/issue_report_screen.dart';
import '../screens/issues/issues_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/shell/client_shell.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/staff/staff_portal_screen.dart';
import '../screens/tracking/tracking_screen.dart';
import '../screens/welcome/welcome_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const orders = '/orders';
  static const chat = '/chat';
  static const profile = '/profile';
  static const bookingTruck = '/booking/truck';
  static const bookingDelivery = '/booking/delivery';
  static const bookingSummary = '/booking/summary';
  static const bookingPayment = '/booking/payment';
  static const bookingSuccess = '/booking/success';
  static const tracking = '/tracking';
  static const issues = '/issues';
  static const issueReport = '/issues/report';
  static const driver = '/driver';
  static const driverOrder = '/driver/orders';
  static const staff = '/staff';

  static String homeForRole(String? role) {
    return switch (role) {
      'operator' => driver,
      'admin' => staff,
      _ => home,
    };
  }

  /// Pop one screen, or land on home if the stack is empty.
  static void popOrHome(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(home);
    }
  }

  /// Replace the stack with a main tab (clears booking/tracking overlays).
  static void leaveToShell(BuildContext context, String location) {
    GoRouter.of(context).go(location);
  }

  /// Empty-draft guards must not fire from booking screens buried under Payment.
  static void leaveHomeIfCurrent(BuildContext context) {
    if (!context.mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    leaveToShell(context, home);
  }

  static bool _isAuthRoute(String location) =>
      location == welcome || location == login || location == register;

  static bool _isDriverRoute(String location) =>
      location == driver || location.startsWith('$driverOrder/');

  static bool _isStaffRoute(String location) => location == staff;

  static bool _isClientRoute(String location) {
    return location == home ||
        location == orders ||
        location == chat ||
        location == profile ||
        location.startsWith('/booking/') ||
        location.startsWith('$tracking/') ||
        location.startsWith('/issues');
  }

  static Widget _tab(String location, Widget child) {
    return ClientShell(location: location, child: child);
  }

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: splash,
      redirect: (context, state) {
        final status = authProvider.status;
        final location = state.matchedLocation;
        final role = authProvider.user?.role;

        if (status == AuthStatus.unknown) {
          return location == splash ? null : splash;
        }

        final isAuthenticated = status == AuthStatus.authenticated;
        final isSplash = location == splash;

        if (!isAuthenticated) {
          if (_isAuthRoute(location)) return null;
          return welcome;
        }

        if (_isAuthRoute(location) || isSplash) {
          return homeForRole(role);
        }

        if (role == 'operator' && !_isDriverRoute(location)) {
          return driver;
        }
        if (role == 'admin' && !_isStaffRoute(location)) {
          return staff;
        }
        if ((role == null || role == 'client') &&
            (_isDriverRoute(location) || _isStaffRoute(location))) {
          return home;
        }

        if ((role == null || role == 'client') && !_isClientRoute(location)) {
          return home;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: splash,
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: welcome,
          builder: (context, state) => const WelcomeScreen(),
        ),
        GoRoute(path: login, builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: register,
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          pageBuilder: (context, state) => NoTransitionPage(
            child: _tab(home, const HomeScreen()),
          ),
        ),
        GoRoute(
          path: orders,
          pageBuilder: (context, state) => NoTransitionPage(
            child: _tab(orders, const OrdersScreen()),
          ),
        ),
        GoRoute(
          path: chat,
          pageBuilder: (context, state) => NoTransitionPage(
            child: _tab(chat, const ChatbotScreen()),
          ),
        ),
        GoRoute(
          path: profile,
          pageBuilder: (context, state) => NoTransitionPage(
            child: _tab(profile, const ProfileScreen()),
          ),
        ),
        GoRoute(
          path: bookingTruck,
          builder: (context, state) => const TruckTypeScreen(),
        ),
        GoRoute(
          path: bookingDelivery,
          builder: (context, state) => const DeliveryLocationScreen(),
        ),
        GoRoute(
          path: bookingSummary,
          builder: (context, state) => const OrderSummaryScreen(),
        ),
        GoRoute(
          path: bookingPayment,
          builder: (context, state) => const PaymentScreen(),
        ),
        GoRoute(
          path: '$bookingSuccess/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return OrderSuccessScreen(orderId: id);
          },
        ),
        GoRoute(
          path: '$tracking/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return TrackingScreen(orderId: id);
          },
        ),
        GoRoute(
          path: issues,
          builder: (context, state) => const IssuesScreen(),
        ),
        GoRoute(
          path: issueReport,
          builder: (context, state) {
            final type = state.uri.queryParameters['type'];
            return IssueReportScreen(prefillType: type);
          },
        ),
        GoRoute(
          path: driver,
          builder: (context, state) => const DriverHomeScreen(),
        ),
        GoRoute(
          path: '$driverOrder/:id',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return DriverOrderDetailScreen(orderId: id);
          },
        ),
        GoRoute(
          path: staff,
          builder: (context, state) => const StaffPortalScreen(),
        ),
      ],
    );
  }
}
