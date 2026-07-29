import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/custom_text_field.dart';
import '../../shared/buttons/primary_button.dart';
import '../../shared/dialogs/custom_snackbar.dart';
import 'support_provider.dart';

class ContactSupportScreen extends ConsumerStatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  ConsumerState<ContactSupportScreen> createState() =>
      _ContactSupportScreenState();
}

class _ContactSupportScreenState extends ConsumerState<ContactSupportScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      CustomSnackbar.show(
        context: context,
        message: "Please fill out all fields",
        isError: true,
      );
      return;
    }

    final success = await ref
        .read(submitTicketControllerProvider.notifier)
        .submit(subject, message);

    if (success && mounted) {
      CustomSnackbar.show(
        context: context,
        message: "Message sent successfully!",
      );
      _subjectController.clear();
      _messageController.clear();
      ref.invalidate(ticketsProvider);
    } else if (mounted) {
      final error = ref.read(submitTicketControllerProvider).error;
      CustomSnackbar.show(
        context: context,
        message: error ?? "Failed to send",
        isError: true,
      );
    }
  }

  String _formatDate(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(submitTicketControllerProvider);
    final ticketsAsync = ref.watch(ticketsProvider);

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
          "Email Support",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.cards,
        onRefresh: () async {
          ref.invalidate(ticketsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Submit Form
              const Text(
                "Send us a message",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Describe your issue and our team will reply as soon as possible.",
                style: TextStyle(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                hintText: "Subject",
                controller: _subjectController,
              ),
              CustomTextField(
                hintText: "Describe your issue...",
                controller: _messageController,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 8),

              PrimaryButton(
                text: "Send Message",
                isLoading: submitState.isLoading,
                onPressed: submitState.isLoading ? () {} : _handleSubmit,
              ),
              const SizedBox(height: 40),
              Divider(color: AppColors.textGrey.withOpacity(0.1)),
              const SizedBox(height: 24),

              // Previous Tickets History
              const Text(
                "Your Messages",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              ticketsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (err, stack) => Center(
                  child: Text(
                    "Error: $err",
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (tickets) {
                  if (tickets.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32.0),
                        child: Text(
                          "No previous messages.",
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tickets.length,
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cards,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.textGrey.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    ticket.subject,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ticket.isReplied
                                        ? AppColors.success.withOpacity(0.1)
                                        : Colors.orangeAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    ticket.isReplied ? "Replied" : "Pending",
                                    style: TextStyle(
                                      color: ticket.isReplied
                                          ? AppColors.success
                                          : Colors.orangeAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(ticket.createdAt),
                              style: const TextStyle(
                                color: AppColors.textGrey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              ticket.message,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),

                            // Admin Reply Box
                            if (ticket.isReplied &&
                                ticket.adminReply != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.support_agent,
                                          color: AppColors.primary,
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "Support Team",
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ticket.adminReply!,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
