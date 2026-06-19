import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/buttons/social_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

              const CustomTextField(
                hintText: "Email",
                keyboardType: TextInputType.emailAddress,
              ),
              const CustomTextField(hintText: "Password", isPassword: true),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: false, // Wire up state later
                        onChanged: (val) {},
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
                text: "Get Started",
                onPressed: () =>
                    context.go('/dashboard'), // Placeholder for post-login
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
                icon: Icons.g_mobiledata, // Placeholder icon
                onPressed: () {},
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
