import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/pricing_card.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'providers/subscription_provider.dart';

class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch User Active Subscription Details directly
    final mySubAsync = ref.watch(mySubscriptionProvider);

    // 2. Fetch Available Plans List
    final plansAsync = ref.watch(subscriptionPlansProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
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

          // --- Dedicated Subscription Usage Card ---
          mySubAsync.when(
            loading: () => Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.textGrey.withOpacity(0.2)),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
            error: (err, stack) => Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Text(
                "Failed to load subscription details: $err",
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (mySub) {
              // UPDATE: Dynamically map limits directly from backend response
              final allocated = mySub.totalAllocatedMinutes;
              final remaining = mySub.remainingMinutes;
              final used = (allocated - remaining).clamp(0.0, allocated);
              final usageRatio = allocated > 0
                  ? (used / allocated).clamp(0.0, 1.0)
                  : 0.0;

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textGrey.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Current Plan",
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "${mySub.planName} Tier",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Usage",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${used.toStringAsFixed(1)} / ${allocated.toStringAsFixed(0)} mins",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: usageRatio,
                      backgroundColor: AppColors.cards,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        usageRatio > 0.9 ? Colors.redAccent : AppColors.accent,
                      ),
                      borderRadius: BorderRadius.circular(4),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "${remaining.toStringAsFixed(1)} minutes remaining. Expires in ${mySub.daysUntilExpiry} days.",
                      style: const TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // --- Refer & Earn ---
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

          // --- Dynamic Pricing Cards ---
          plansAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (err, stack) => Center(
              child: Text(
                "Error loading plans: $err",
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            data: (plans) {
              final activePlanName = mySubAsync.value?.planName ?? "Free";

              return Column(
                children: plans.map((plan) {
                  final isCurrent =
                      plan.name.toLowerCase() == activePlanName.toLowerCase();

                  final displayFeatures = [
                    "${plan.allocatedMinutes} Minutes included",
                    "Max Upload: ${plan.maxUploadMb} MB",
                    "${plan.exportResolution}p Export Resolution",
                    if (!plan.hasWatermark) "No Watermark",
                    ...plan.features,
                  ];

                  return PricingCard(
                    title: plan.name,
                    price: plan.price == "0.00" ? "Free" : "\$${plan.price}",
                    duration: plan.price == "0.00" ? "" : plan.duration,
                    isPopular: plan.isPopular,
                    isCurrentPlan: isCurrent,
                    onAction: () async {
                      if (plan.name.toLowerCase() == 'free') {
                        CustomSnackbar.show(
                          context: context,
                          message: "You are already on the Free plan.",
                        );
                      } else {
                        try {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (ctx) => const Center(
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );

                          final checkoutUrl = await ref
                              .read(subscriptionRepositoryProvider)
                              .createCheckoutSession(plan.id);

                          if (context.mounted) {
                            Navigator.pop(context); // Close loading dialog

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                    backgroundColor: AppColors.cards,
                                    title: const Text(
                                      "Secure Checkout",
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  body: InAppWebView(
                                    initialUrlRequest: URLRequest(
                                      url: WebUri(checkoutUrl),
                                    ),
                                    onUpdateVisitedHistory:
                                        (controller, url, androidIsReload) {
                                          if (url != null) {
                                            final urlString = url.toString();

                                            if (urlString.contains(
                                                  '/subscriptions/success',
                                                ) ||
                                                urlString.contains(
                                                  'success=true',
                                                )) {
                                              Navigator.pop(context);
                                              ref.invalidate(
                                                mySubscriptionProvider,
                                              );
                                              CustomSnackbar.show(
                                                context: context,
                                                message:
                                                    "Payment Successful! Subscription activated.",
                                              );
                                            } else if (urlString.contains(
                                              'cancel',
                                            )) {
                                              Navigator.pop(context);
                                              CustomSnackbar.show(
                                                context: context,
                                                message: "Payment Cancelled.",
                                                isError: true,
                                              );
                                            }
                                          }
                                        },
                                  ),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            CustomSnackbar.show(
                              context: context,
                              message:
                                  "Failed to initiate checkout. Please try again.",
                              isError: true,
                            );
                          }
                        }
                      }
                    },
                    features: displayFeatures,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
