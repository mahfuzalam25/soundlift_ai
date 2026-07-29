import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// --- USER SUBSCRIPTION MODEL ---
class UserSubscription {
  final String id;
  final String planName;
  final String status;
  final bool isActive;
  final String currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final int daysUntilExpiry;
  final double remainingMinutes;
  final double totalAllocatedMinutes; // NEW: Added from backend

  UserSubscription({
    required this.id,
    required this.planName,
    required this.status,
    required this.isActive,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
    required this.daysUntilExpiry,
    required this.remainingMinutes,
    required this.totalAllocatedMinutes, // NEW
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] ?? '',
      planName: json['plan_name'] ?? 'Free',
      status: json['status'] ?? 'active',
      isActive: json['is_active'] ?? true,
      currentPeriodEnd: json['current_period_end'] ?? '',
      cancelAtPeriodEnd: json['cancel_at_period_end'] ?? false,
      daysUntilExpiry: json['days_until_expiry'] ?? 0,
      remainingMinutes: (json['remaining_minutes'] ?? 0.0).toDouble(),
      totalAllocatedMinutes: (json['total_allocated_minutes'] ?? 0.0).toDouble(), // NEW
    );
  }
}

// --- SUBSCRIPTION PLAN MODEL ---
class SubscriptionPlan {
  final String id;
  final String name;
  final String price;
  final String duration;
  final bool isPopular;
  final int allocatedMinutes;
  final int maxStorageMb;
  final int maxUploadMb;
  final int exportResolution;
  final bool hasWatermark;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.duration,
    required this.isPopular,
    required this.allocatedMinutes,
    required this.maxStorageMb,
    required this.maxUploadMb,
    required this.exportResolution,
    required this.hasWatermark,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown',
      price: json['price'] ?? '0.00',
      duration: json['duration'] ?? '/month',
      isPopular: json['is_popular'] ?? false,
      allocatedMinutes: json['allocated_minutes'] ?? 0,
      maxStorageMb: json['max_storage_mb'] ?? 0,
      maxUploadMb: json['max_upload_mb'] ?? 0,
      exportResolution: json['export_resolution'] ?? 720,
      hasWatermark: json['has_watermark'] ?? true,
      features: List<String>.from(json['features'] ?? []),
    );
  }
}

// --- REPOSITORY ---
class SubscriptionRepository {
  final Dio _dio;
  SubscriptionRepository(this._dio);

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _dio.get('/api/subscriptions/plans/');
    return (response.data as List)
        .map((json) => SubscriptionPlan.fromJson(json))
        .toList();
  }

  Future<UserSubscription> getMySubscription() async {
    final response = await _dio.get('/api/subscriptions/my-subscription/');
    return UserSubscription.fromJson(response.data);
  }

  Future<String> createCheckoutSession(String planId) async {
    final response = await _dio.post(
      '/api/subscriptions/create-checkout-session/',
      data: {'plan_id': planId},
    );
    return response.data['checkout_url'];
  }
}

final subscriptionRepositoryProvider = Provider(
  (ref) => SubscriptionRepository(ref.watch(dioProvider)),
);

// --- PROVIDERS ---
final subscriptionPlansProvider =
    FutureProvider.autoDispose<List<SubscriptionPlan>>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return await repository.getPlans();
});

final mySubscriptionProvider =
    FutureProvider.autoDispose<UserSubscription>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return await repository.getMySubscription();
});