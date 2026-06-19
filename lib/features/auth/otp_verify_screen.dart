import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';

class OtpVerifyScreen extends StatelessWidget {
  final String flow; // 'register' or 'reset'
  const OtpVerifyScreen({super.key, required this.flow});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Verify OTP",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the 6-digit code sent to your email.",
              style: TextStyle(color: AppColors.textGrey, fontSize: 16),
            ),
            const SizedBox(height: 40),
            const CustomTextField(
              hintText: "OTP Code",
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              text: "Verify",
              onPressed: () {
                if (flow == 'reset') {
                  context.push('/auth/new-password');
                } else {
                  context.go('/dashboard'); // Reg success
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
