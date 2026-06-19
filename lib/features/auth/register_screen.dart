import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
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
            const SizedBox(height: 8),
            const Text(
              "Join SoundLift AI to elevate your audio.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),

            Row(
              children: const [
                Expanded(child: CustomTextField(hintText: "First Name")),
                SizedBox(width: 16),
                Expanded(child: CustomTextField(hintText: "Last Name")),
              ],
            ),
            const CustomTextField(
              hintText: "Email",
              keyboardType: TextInputType.emailAddress,
            ),
            const CustomTextField(hintText: "Password", isPassword: true),
            const CustomTextField(
              hintText: "Confirm Password",
              isPassword: true,
            ),

            const SizedBox(height: 24),
            PrimaryButton(
              text: "Register",
              onPressed: () => context.push('/auth/verify?flow=register'),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account? ",
                  style: TextStyle(color: AppColors.textGrey),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text(
                    "Login",
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
