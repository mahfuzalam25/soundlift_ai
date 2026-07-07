import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/buttons/social_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'auth_provider.dart';
import '../profile/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please fill all fields",
        isError: true,
      );
      return;
    }

    final result = await ref
        .read(authControllerProvider.notifier)
        .login(_emailController.text.trim(), _passwordController.text);

    if (mounted) {
      if (result == LoginResult.requires2FA) {
        CustomSnackbar.show(
          context: context,
          message: "2FA code sent to your email.",
        );
        context.push('/auth/verify?flow=2fa');
      } else if (result == LoginResult.success) {
        ref.invalidate(profileControllerProvider);
        context.go('/dashboard');
      } else {
        final error = ref.read(authControllerProvider).error;
        CustomSnackbar.show(
          context: context,
          message: error ?? "Login failed",
          isError: true,
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    final success = await ref
        .read(authControllerProvider.notifier)
        .handleGoogleAuth();
    if (success && mounted) {
      ref.invalidate(profileControllerProvider);
      context.go('/dashboard');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      if (error != null) {
        CustomSnackbar.show(context: context, message: error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Let's sign in",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Welcome Back, You have been missed.",
                style: TextStyle(color: AppColors.textGrey, fontSize: 16),
              ),
              const SizedBox(height: 40),

              CustomTextField(
                hintText: "Email",
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              CustomTextField(
                hintText: "Password",
                controller: _passwordController,
                isPassword: true,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (val) => setState(() => _rememberMe = val!),
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => AppColors.cards,
                        ),
                        checkColor: AppColors.primary,
                      ),
                      const Text(
                        "Remember Me",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push('/auth/forgot-password'),
                    child: const Text(
                      "Forgot Password",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              PrimaryButton(
                text: "Login",
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? () {} : _handleLogin,
              ),

              const SizedBox(height: 32),
              const Center(
                child: Text(
                  "or continue with",
                  style: TextStyle(color: AppColors.textGrey),
                ),
              ),
              const SizedBox(height: 24),

              SocialButton(
                text: "Continue with Google",
                icon: Icons.g_mobiledata,
                onPressed: authState.isLoading ? () {} : _handleGoogleLogin,
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                  TextButton(
                    onPressed: () => context.push('/auth/register'),
                    child: const Text(
                      "Register Now",
                      style: TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
