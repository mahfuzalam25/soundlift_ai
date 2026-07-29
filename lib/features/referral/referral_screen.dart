import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/widgets/custom_text_field.dart'; // Ensure this matches your path
import '../../shared/dialogs/custom_snackbar.dart';
import 'providers/referral_provider.dart';

class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _handleClaim() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please enter a code",
        isError: true,
      );
      return;
    }

    // Unfocus keyboard
    FocusScope.of(context).unfocus();
    await ref.read(claimReferralProvider.notifier).claim(code);
  }

  @override
  Widget build(BuildContext context) {
    final referralDataAsync = ref.watch(referralDataProvider);
    final claimState = ref.watch(claimReferralProvider);

    // Listen to the claim state to show success/error snackbars
    ref.listen<AsyncValue<void>>(claimReferralProvider, (prev, next) {
      next.when(
        data: (_) {
          if (prev is AsyncLoading) {
            CustomSnackbar.show(
              context: context,
              message: "Referral code claimed! You earned 50 free minutes.",
            );
            _codeController.clear();
          }
        },
        error: (err, stack) {
          CustomSnackbar.show(
            context: context,
            message: err.toString(),
            isError: true,
          );
        },
        loading: () {},
      );
    });

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
          "Refer & Earn",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: referralDataAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Hero Graphic
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    size: 64,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 24),

                // Hero Text
                const Text(
                  "Invite Friends,\nEarn Free Minutes",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Give your friends 50 free processing minutes and get 50 minutes for yourself when they sign up.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textGrey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                // --- Claim Friend's Code Section (Hides if already claimed) ---
                if (!data.hasClaimedWelcomeReward) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.cards,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          "Were you invited?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Enter your friend's code to claim 50 free minutes.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: "Enter Referral Code",
                          controller: _codeController,
                        ),
                        PrimaryButton(
                          text: "Claim Reward",
                          isLoading: claimState.isLoading,
                          onPressed: _handleClaim,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],

                // Share Code Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "Your Unique Referral Code",
                        style: TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.textGrey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          data.code,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: "Copy Link",
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(
                              text: "https://soundlift.ai/invite/${data.code}",
                            ),
                          );
                          CustomSnackbar.show(
                            context: context,
                            message: "Referral link copied to clipboard!",
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Stats Section
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        "Friends Invited",
                        "${data.totalReferrals}",
                        Icons.people,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        "Minutes Earned",
                        "${data.totalEarnedMinutes.toInt()}",
                        Icons.timer,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // How it works
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "How it works",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildStepRow(
                  "1",
                  "Share your code",
                  "Send your unique link or code to your friends.",
                ),
                _buildStepRow(
                  "2",
                  "They sign up",
                  "Your friend creates an account using your link.",
                ),
                _buildStepRow(
                  "3",
                  "Get rewarded",
                  "Both of you receive 50 free minutes instantly.",
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textGrey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
