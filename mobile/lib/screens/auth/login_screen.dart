import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../core/api_exception.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });
  }

  String? _validateLocally() {
    if (_emailController.text.trim().isEmpty) {
      return 'Enter your email to sign in.';
    }
    if (_passwordController.text.isEmpty) {
      return 'Enter your password to continue.';
    }
    return null;
  }

  Future<void> _submit() async {
    _clearErrors();

    final localError = _validateLocally();
    if (localError != null) {
      setState(() => _generalError = localError);
      return;
    }

    try {
      await context.read<AuthProvider>().login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = e.fieldError('email');
        _passwordError = e.fieldError('password');
        if (e.fieldErrors.isEmpty) {
          _generalError = e.message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bone,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.welcome),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome back',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue ordering.',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppTheme.slate),
            ),
            const SizedBox(height: 32),
            if (_generalError != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFF5C6C2)),
                ),
                child: Text(
                  _generalError!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB3261E),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            AppTextField(
              controller: _emailController,
              label: 'Email',
              errorText: _emailError,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onChanged: (_) => _clearErrors(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              errorText: _passwordError,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onChanged: (_) => _clearErrors(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppTheme.slate,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            const SizedBox(height: 28),
            AppButton(
              label: 'Sign in',
              loading: authProvider.loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: Text.rich(
                  TextSpan(
                    text: 'No account yet? ',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.slate),
                    children: [
                      TextSpan(
                        text: 'Create one',
                        style: TextStyle(
                          color: AppTheme.tipperAmber,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
