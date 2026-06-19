import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/widgets/action_card.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Help Center",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "How can we help you?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Search Bar
            const CustomTextField(
              hintText: "Search for articles, tutorials...",
              prefixIcon: Icon(Icons.search, color: AppColors.textGrey),
            ),
            const SizedBox(height: 32),

            // Categories Grid
            const Text(
              "Categories",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                ActionCard(
                  title: "FAQ",
                  icon: Icons.question_answer_outlined,
                  onTap: () {
                    CustomSnackbar.show(
                      context: context,
                      message: "Opening FAQ...",
                    );
                  },
                ),
                ActionCard(
                  title: "Tutorials",
                  icon: Icons.play_circle_outline,
                  onTap: () {
                    CustomSnackbar.show(
                      context: context,
                      message: "Opening Tutorials...",
                    );
                  },
                ),
                ActionCard(
                  title: "Documentation",
                  icon: Icons.library_books_outlined,
                  onTap: () {
                    CustomSnackbar.show(
                      context: context,
                      message: "Opening Documentation...",
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Contact Support Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.support_agent,
                    size: 48,
                    color: AppColors.accent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Still need help?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Our support team is available 24/7 to assist you with any technical issues.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    text: "Contact Support",
                    onPressed: () {
                      context.push('/support');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
