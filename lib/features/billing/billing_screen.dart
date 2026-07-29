import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../shared/widgets/invoice_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'providers/billing_provider.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return "N/A";
    try {
      final date = DateTime.parse(isoDate).toLocal();
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return "Unknown Date";
    }
  }

  Future<void> _downloadInvoice(String invoiceId, String invoiceNumber) async {
    try {
      CustomSnackbar.show(
        context: context,
        message: "Downloading $invoiceNumber as PDF...",
      );

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception("Could not access local storage.");
      }

      String savePath = "${directory.path}/$invoiceNumber.pdf";

      // We read the global dioProvider so that the interceptors attach the Auth token automatically!
      final dio = ref.read(dioProvider);

      await dio.download('/api/billing/invoices/$invoiceId/pdf/', savePath);

      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Saved successfully to your device:\n$savePath",
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context: context,
          message: "Failed to download invoice.",
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(billingOverviewProvider);

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
          "Billing & Payments",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: overviewAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error loading billing data: $err",
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (overview) {
          final plan = overview.currentPlan;
          final invoices = overview.recentInvoices;

          // Dynamically format the price to handle "Free" vs paid amounts
          final displayPrice = plan.price == "0.00"
              ? "Free"
              : "\$${plan.price} ${plan.duration.replaceAll('/', '/ ')}";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current Plan & Renewal Overview
                const Text(
                  "Overview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              plan.status.isNotEmpty
                                  ? plan.status
                                  : "${plan.name} Tier",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // DYNAMIC PRICE DISPLAY APPLIED HERE
                      Text(
                        displayPrice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(color: AppColors.background, thickness: 2),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                color: AppColors.textGrey.withOpacity(0.8),
                              ),
                              const SizedBox(width: 12),
                              // Static as requested
                              const Text(
                                "Visa ending in 4242",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () {
                              CustomSnackbar.show(
                                context: context,
                                message: "Update Payment Method coming soon",
                              );
                            },
                            child: const Text(
                              "Edit",
                              style: TextStyle(color: AppColors.accent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.currentPeriodEnd != null
                            ? "Next renewal on ${_formatDate(plan.currentPeriodEnd)}"
                            : "No upcoming renewals.",
                        style: const TextStyle(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Billing History
                const Text(
                  "Billing History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (invoices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "No billing history found.",
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    ),
                  )
                else
                  ...invoices.map((invoice) {
                    return InvoiceTile(
                      invoiceId: invoice.invoiceNumber,
                      date: _formatDate(invoice.createdAt),
                      amount: "\$${invoice.amount}",
                      isPaid: invoice.status.toLowerCase() == 'paid',
                      onDownload: () =>
                          _downloadInvoice(invoice.id, invoice.invoiceNumber),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
