import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/welcome/welcome_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const welcome = '/welcome';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      refreshListenable: authProvider,
      initialLocation: splash,
      redirect: (context, state) {
        final status = authProvider.status;
        final location = state.matchedLocation;

        if (status == AuthStatus.unknown) {
          return location == splash ? null : splash;
        }

        final isAuthenticated = status == AuthStatus.authenticated;
        final isAuthRoute =
            location == welcome || location == login || location == register;
        final isSplash = location == splash;

        if (!isAuthenticated && !isAuthRoute) {
          return welcome;
        }

        if (isAuthenticated && (isAuthRoute || isSplash)) {
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
        GoRoute(path: home, builder: (context, state) => const HomeScreen()),
      ],
    );
  }
}
