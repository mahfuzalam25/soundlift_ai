import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Added GoRouter for navigation
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pricing_card.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // UPDATED: Wrapped header in a Row to add the Billing button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Subscription",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/subscription/billing'),
                icon: const Icon(
                  Icons.receipt_long,
                  color: AppColors.accent,
                  size: 20,
                ),
                label: const Text(
                  "Billing",
                  style: TextStyle(color: AppColors.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Usage Card (Unchanged)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.textGrey.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Current Plan",
                      style: TextStyle(color: AppColors.textGrey, fontSize: 14),
                    ),
                    Text(
                      "Free Tier",
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Usage",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "45 / 60 mins",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: 45 / 60,
                  backgroundColor: AppColors.cards,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accent,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
                const SizedBox(height: 16),
                const Text(
                  "15 minutes remaining this month. Renews on Jul 12, 2026.",
                  style: TextStyle(color: AppColors.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.push('/referrals'),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.card_giftcard, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Refer & Earn Credits",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Invite friends and get 50 free minutes!",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),

          const Text(
            "Upgrade Plans",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Pricing Cards (Unchanged)
          PricingCard(
            title: "Pro",
            price: "\$19.99",
            duration: "/month",
            isPopular: true,
            features: [
              "500 Minutes of processing",
              "Advanced AI Noise Removal",
              "1080p Video Export",
              "Priority Queueing",
            ],
            onAction: () {
              CustomSnackbar.show(
                context: context,
                message: "Redirecting to Stripe payment...",
              );
            },
          ),

          PricingCard(
            title: "Business",
            price: "\$49.99",
            duration: "/month",
            features: [
              "2000 Minutes of processing",
              "Studio-Grade Audio Enhancement",
              "4K Video Export",
              "API Access & Team Collaboration",
            ],
            onAction: () {
              CustomSnackbar.show(
                context: context,
                message: "Redirecting to Stripe payment...",
              );
            },
          ),

          PricingCard(
            title: "Enterprise",
            price: "Custom",
            duration: "",
            features: [
              "Unlimited Minutes",
              "Dedicated Account Manager",
              "Custom AI Model Training",
              "On-Premise Deployment Options",
            ],
            onAction: () {
              CustomSnackbar.show(
                context: context,
                message: "Opening contact form...",
              );
            },
          ),
        ],
      ),
    );
  }
}
