import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import 'security_provider.dart';

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  String _formatDate(DateTime date) {
    final yyyy = date.year;
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "$yyyy-$mm-$dd at $hh:$min";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);

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
          "Login History & Sessions",
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(
          child: Text("Error loading sessions: $err", style: const TextStyle(color: Colors.redAccent)),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(
              child: Text("No sessions found.", style: TextStyle(color: AppColors.textGrey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cards,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.textGrey.withOpacity(0.1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: session.isActive 
                            ? AppColors.success.withOpacity(0.1) 
                            : AppColors.textGrey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        session.userAgent.contains('Dart') ? Icons.phone_android : Icons.computer,
                        color: session.isActive ? AppColors.success : AppColors.textGrey,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                session.ipAddress,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              if (session.isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text("Active", style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            session.userAgent,
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(session.loginDatetime),
                            style: const TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}