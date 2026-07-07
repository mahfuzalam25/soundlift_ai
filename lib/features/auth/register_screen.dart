import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'auth_provider.dart';
import '../../shared/buttons/social_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_passwordController.text != _confirmController.text) {
      CustomSnackbar.show(
        context: context,
        message: "Passwords do not match",
        isError: true,
      );
      return;
    }

    final success = await ref
        .read(authControllerProvider.notifier)
        .register(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          confirmPassword: _confirmController.text,
        );

    if (success && mounted) {
      CustomSnackbar.show(context: context, message: "OTP sent to your email!");
      context.push('/auth/verify?flow=register');
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      CustomSnackbar.show(
        context: context,
        message: error ?? "Registration failed",
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Let's register account",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),

            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    hintText: "First Name",
                    controller: _firstNameController,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomTextField(
                    hintText: "Last Name",
                    controller: _lastNameController,
                  ),
                ),
              ],
            ),
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
            CustomTextField(
              hintText: "Confirm Password",
              controller: _confirmController,
              isPassword: true,
            ),

            const SizedBox(height: 24),
            PrimaryButton(
              text: "Register",
              isLoading: authState.isLoading,
              onPressed: authState.isLoading ? () {} : _handleRegister,
            ),
            const SizedBox(height: 24),
            const Center(
              child: Text(
                "or continue with",
                style: TextStyle(color: AppColors.textGrey),
              ),
            ),
            const SizedBox(height: 24),

            SocialButton(
              text: "Sign up with Google",
              icon: Icons.g_mobiledata,
              onPressed: authState.isLoading
                  ? () {}
                  : () async {
                      final success = await ref
                          .read(authControllerProvider.notifier)
                          .handleGoogleAuth();
                      if (success && mounted) {
                        context.go('/dashboard');
                      } else if (mounted) {
                        final error = ref.read(authControllerProvider).error;
                        if (error != null) {
                          CustomSnackbar.show(
                            context: context,
                            message: error,
                            isError: true,
                          );
                        }
                      }
                    },
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
                  onPressed: () => context.push('/auth/login'),
                  child: const Text(
                    "Login Now",
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
