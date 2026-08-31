import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:tippertruck/core/api_exception.dart';
import 'package:tippertruck/providers/auth_provider.dart';
import 'package:tippertruck/screens/auth/login_screen.dart';

class MockAuthProvider extends Mock implements AuthProvider {
  final AuthStatus _status = AuthStatus.unauthenticated;
  bool _loading = false;

  @override
  AuthStatus get status => _status;

  @override
  bool get loading => _loading;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

Widget buildTestWidget(MockAuthProvider authProvider) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const Scaffold(body: Text('Register')),
      ),
    ],
  );

  return ChangeNotifierProvider<AuthProvider>.value(
    value: authProvider,
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  late MockAuthProvider mockAuth;

  setUp(() {
    mockAuth = MockAuthProvider();
  });

  testWidgets('shows email and password fields', (tester) async {
    await tester.pumpWidget(buildTestWidget(mockAuth));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
  });

  testWidgets('shows local validation error when fields are empty', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(mockAuth));
    await tester.pumpAndSettle();

    // Tap sign in without filling fields
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email address.'), findsOneWidget);
  });

  testWidgets('shows server validation errors on form fields', (tester) async {
    when(
      () => mockAuth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ApiException(
        statusCode: 422,
        message: 'The given data was invalid.',
        fieldErrors: {
          'email': ['The email field must be a valid email address.'],
        },
      ),
    );

    await tester.pumpWidget(buildTestWidget(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'bad-email',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'password123',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.text('The email field must be a valid email address.'),
      findsOneWidget,
    );
  });

  testWidgets('shows general error message for bad credentials', (
    tester,
  ) async {
    when(
      () => mockAuth.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(
      const ApiException(
        statusCode: 401,
        message: 'These credentials do not match our records.',
      ),
    );

    await tester.pumpWidget(buildTestWidget(mockAuth));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'test@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'wrongpassword',
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pumpAndSettle();

    expect(
      find.text('These credentials do not match our records.'),
      findsOneWidget,
    );
  });

  testWidgets('loading state disables button and shows spinner', (
    tester,
  ) async {
    mockAuth._loading = true;

    await tester.pumpWidget(buildTestWidget(mockAuth));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });
}
