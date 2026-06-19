import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class InvoiceTile extends StatelessWidget {
  final String invoiceId;
  final String date;
  final String amount;
  final bool isPaid;
  final VoidCallback onDownload;

  const InvoiceTile({
    super.key,
    required this.invoiceId,
    required this.date,
    required this.amount,
    this.isPaid = true,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Invoice $invoiceId",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("•", style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
                    ),
                    Text(
                      amount,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPaid ? AppColors.success.withOpacity(0.1) : Colors.orangeAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isPaid ? "Paid" : "Pending",
              style: TextStyle(
                color: isPaid ? AppColors.success : Colors.orangeAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download_rounded, color: AppColors.accent),
            tooltip: "Download PDF",
          ),
        ],
      ),
    );
  }
}