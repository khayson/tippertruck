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
import '../../widgets/social_auth_buttons.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearErrors() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;
    });
  }

  String? _validateLocally() {
    if (_nameController.text.trim().isEmpty) return 'Enter your full name.';
    if (_emailController.text.trim().isEmpty) return 'Enter your email.';
    if (_passwordController.text.isEmpty) return 'Choose a password.';
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (_confirmController.text != _passwordController.text) {
      return 'Passwords do not match.';
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
      await auth.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      context.go(AppRoutes.homeForRole(auth.user?.role));
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _nameError = e.fieldError('name');
        _emailError = e.fieldError('email');
        _phoneError = e.fieldError('phone');
        _passwordError = e.fieldError('password');
        _confirmError = e.fieldError('password_confirmation');
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
      await auth.loginWithSocial(
        provider: provider,
        mode: mode,
      );
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
                      'Sign up',
                      style: GoogleFonts.archivoBlack(
                        fontSize: 40,
                        height: 1.1,
                        letterSpacing: -0.8,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Create an account to order tipper loads of sand and track every delivery.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.slate,
                        height: 1.5,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 40),
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFFB3261E)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'Your full name',
                      errorText: _nameError,
                      keyboardType: TextInputType.name,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearErrors(),
                      variant: AppTextFieldVariant.underline,
                      suffixIcon: Icon(
                        Icons.person_outline_rounded,
                        color: iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 28),
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
                      controller: _phoneController,
                      label: 'Phone (optional)',
                      hint: '0241234567',
                      errorText: _phoneError,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearErrors(),
                      variant: AppTextFieldVariant.underline,
                      suffixIcon: Icon(
                        Icons.phone_outlined,
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
                      textInputAction: TextInputAction.next,
                      onChanged: (_) => _clearErrors(),
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
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _confirmController,
                      label: 'Confirm password',
                      hint: '••••••••••••••',
                      errorText: _confirmError,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => _clearErrors(),
                      onSubmitted: (_) => _submit(),
                      variant: AppTextFieldVariant.underline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: iconColor,
                          size: 22,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirm = !_obscureConfirm,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    AppButton(
                      label: 'Sign Up',
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
                          label: 'Or sign up with',
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
                  onPressed: () => context.go(AppRoutes.login),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 48),
                  ),
                  child: Text.rich(
                    TextSpan(
                      text: 'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.slate,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign In',
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
