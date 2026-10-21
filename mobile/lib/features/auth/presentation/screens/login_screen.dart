import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../auth_controller.dart';
import '../auth_form_utils.dart';
import '../widgets/auth_logo_badge.dart';
import '../widgets/auth_text_field.dart';

/// S-02 Login (`DESIGN.md` S-02).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final emailError = validateEmail(_emailController.text);
    final passwordError = validatePassword(_passwordController.text);
    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (emailError != null || passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // On success the router redirects to /dashboard automatically.
    } on ApiException catch (error) {
      if (!mounted) return;
      final emailFieldError = fieldError(error, 'email');
      final passwordFieldError = fieldError(error, 'password');
      setState(() {
        _emailError = emailFieldError;
        _passwordError = passwordFieldError;
      });
      if (emailFieldError == null && passwordFieldError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(humanizeAuthError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AuthLogoBadge(),
              const SizedBox(height: 32),
              Text(
                'Welcome back',
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Log in to continue your day, one task at a time.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                key: const ValueKey('login_email'),
                controller: _emailController,
                hintText: 'you@example.com',
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                key: const ValueKey('login_password'),
                controller: _passwordController,
                hintText: 'Password',
                leadingIcon: LucideIcons.lock,
                obscureText: true,
                textInputAction: TextInputAction.done,
                errorText: _passwordError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const ValueKey('login_submit'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Log In'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.register),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'New to LifeOS? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: 'Create an account',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
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
      ),
    );
  }
}
