import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/invoice_tile.dart';
import '../../shared/dialogs/custom_snackbar.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

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
          "Billing & Payments",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current Plan & Renewal Overview
            const Text(
              "Overview",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Current Plan", style: TextStyle(color: AppColors.textGrey, fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text("Pro Tier", style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("\$19.99 / month", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.background, thickness: 2),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.credit_card, color: AppColors.textGrey.withOpacity(0.8)),
                          const SizedBox(width: 12),
                          const Text("Visa ending in 4242", style: TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          CustomSnackbar.show(context: context, message: "Update Payment Method coming soon");
                        },
                        child: const Text("Edit", style: TextStyle(color: AppColors.accent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("Next renewal on Dec 12, 2026", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Billing History
            const Text(
              "Billing History",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            InvoiceTile(
              invoiceId: "#INV-2026-11",
              date: "Nov 12, 2026",
              amount: "\$19.99",
              isPaid: true,
              onDownload: () => _downloadInvoice(context, "#INV-2026-11"),
            ),
            InvoiceTile(
              invoiceId: "#INV-2026-10",
              date: "Oct 12, 2026",
              amount: "\$19.99",
              isPaid: true,
              onDownload: () => _downloadInvoice(context, "#INV-2026-10"),
            ),
            InvoiceTile(
              invoiceId: "#INV-2026-09",
              date: "Sep 12, 2026",
              amount: "\$19.99",
              isPaid: true,
              onDownload: () => _downloadInvoice(context, "#INV-2026-09"),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadInvoice(BuildContext context, String invoiceId) {
    CustomSnackbar.show(
      context: context, 
      message: "Downloading $invoiceId as PDF...",
    );
  }
}