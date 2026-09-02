import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../config/routes.dart';
import '../../core/api_exception.dart';
import '../../models/config_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/config_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/social_auth_buttons.dart';

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
      final auth = context.read<AuthProvider>();
      await auth.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      context.go(AppRoutes.homeForRole(auth.user?.role));
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

  Future<void> _socialLogin(String provider, String mode) async {
    _clearErrors();
    try {
      final auth = context.read<AuthProvider>();
      await auth.loginWithSocial(provider: provider, mode: mode);
      if (!mounted) return;
      context.go(AppRoutes.homeForRole(auth.user?.role));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _generalError = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final iconColor = AppTheme.slate.withValues(alpha: 0.65);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                color: AppTheme.ink,
                onPressed: () => context.go(AppRoutes.welcome),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sign in',
                      style: GoogleFonts.archivoBlack(
                        fontSize: 40,
                        height: 1.1,
                        letterSpacing: -0.8,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Experience sand delivery at your fingertips — book a tipper and track it to site.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.slate,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
                    if (_generalError != null) ...[
                      _AuthErrorBanner(message: _generalError!),
                      const SizedBox(height: 24),
                    ],
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'example@gmail.com',
                      errorText: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearErrors(),
                      variant: AppTextFieldVariant.underline,
                      suffixIcon: Icon(
                        Icons.mail_outline_rounded,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '••••••••••••••',
                      errorText: _passwordError,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _clearErrors(),
                      onSubmitted: (_) => _submit(),
                      variant: AppTextFieldVariant.underline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: iconColor,
                          size: 22,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        AppToast.info(
                          context,
                          'Password reset is not available in this release.',
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(48, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        alignment: Alignment.centerLeft,
                      ),
                      child: Text(
                        'Forgot password?',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.ink,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AppTheme.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppButton(
                      label: 'Sign In',
                      dark: true,
                      large: true,
                      loading: authProvider.loading,
                      onPressed: _submit,
                    ),
                    const SizedBox(height: 36),
                    Consumer<ConfigProvider>(
                      builder: (context, configProvider, _) {
                        final social =
                            configProvider.config?.socialAuth ??
                            const SocialAuthConfig(
                              mode: 'simulated',
                              providers: ['google', 'facebook'],
                            );
                        return SocialAuthButtons(
                          label: 'Or sign in with',
                          providers: social.providers,
                          loading: authProvider.loading,
                          onProviderPressed: (provider) =>
                              _socialLogin(provider, social.mode),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 20),
              child: Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppTheme.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                        ),
                      ],
                    ),
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

class _AuthErrorBanner extends StatelessWidget {
  final String message;

  const _AuthErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE8E6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF5C6C2)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB3261E)),
      ),
    );
  }
}
