import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/router.dart';
import '../../../../app/theme.dart';
import '../../../../core/errors/api_exception.dart';
import '../../../../core/notifications/local_notification_service.dart';
import '../auth_controller.dart';
import '../auth_form_utils.dart';
import '../widgets/auth_logo_badge.dart';
import '../widgets/auth_text_field.dart';

/// S-03 Register (`DESIGN.md` S-03) with auto-detected IANA timezone chip.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _timezone;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _detectTimezone();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _detectTimezone() async {
    final timezone = await LocalNotificationService.detectLocalTimezone();
    if (mounted) {
      setState(() => _timezone = timezone);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final nameError = validateRequiredName(_nameController.text);
    final emailError = validateEmail(_emailController.text);
    final passwordError = validatePassword(_passwordController.text);
    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
    });
    if (nameError != null || emailError != null || passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(authControllerProvider.notifier).register(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            timezone: _timezone ?? 'Asia/Jakarta',
          );
      // On success the router redirects to /dashboard automatically.
    } on ApiException catch (error) {
      if (!mounted) return;
      if (error.statusCode == 409) {
        setState(() => _emailError = 'Email sudah terdaftar.');
      } else {
        final nameFieldError = fieldError(error, 'name');
        final emailFieldError = fieldError(error, 'email');
        final passwordFieldError = fieldError(error, 'password');
        setState(() {
          _nameError = nameFieldError;
          _emailError = emailFieldError;
          _passwordError = passwordFieldError;
        });
        if (nameFieldError == null &&
            emailFieldError == null &&
            passwordFieldError == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(humanizeAuthError(error))),
          );
        }
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
                'Create Account',
                style: textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set up your account and start organizing your day.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                key: const ValueKey('register_name'),
                controller: _nameController,
                hintText: 'Full name',
                leadingIcon: LucideIcons.user,
                textInputAction: TextInputAction.next,
                errorText: _nameError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                key: const ValueKey('register_email'),
                controller: _emailController,
                hintText: 'you@example.com',
                leadingIcon: LucideIcons.mail,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),
              AuthTextField(
                key: const ValueKey('register_password'),
                controller: _passwordController,
                hintText: 'Password (min. 8 karakter)',
                leadingIcon: LucideIcons.lock,
                obscureText: true,
                textInputAction: TextInputAction.done,
                errorText: _passwordError,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              _TimezoneChip(timezone: _timezone),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const ValueKey('register_submit'),
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
                    : const Text('Create Account'),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Already have an account? ',
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        TextSpan(
                          text: 'Log In',
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

class _TimezoneChip extends StatelessWidget {
  const _TimezoneChip({required this.timezone});

  final String? timezone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            LucideIcons.globe,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            timezone ?? 'Mendeteksi zona waktu…',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
