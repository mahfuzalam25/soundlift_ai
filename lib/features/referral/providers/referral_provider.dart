import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../subscription/providers/subscription_provider.dart';

// --- MODEL ---
class ReferralData {
  final String code;
  final int totalReferrals;
  final double totalEarnedMinutes;
  final bool hasClaimedWelcomeReward;

  ReferralData({
    required this.code,
    required this.totalReferrals,
    required this.totalEarnedMinutes,
    required this.hasClaimedWelcomeReward,
  });

  factory ReferralData.fromJson(Map<String, dynamic> json) {
    return ReferralData(
      code: json['code'] ?? '',
      totalReferrals: json['total_referrals'] ?? 0,
      totalEarnedMinutes: (json['total_earned_minutes'] ?? 0.0).toDouble(),
      hasClaimedWelcomeReward: json['has_claimed_welcome_reward'] ?? false,
    );
  }
}

// --- REPOSITORY ---
class ReferralRepository {
  final Dio _dio;
  ReferralRepository(this._dio);

  Future<ReferralData> getMyReferral() async {
    final response = await _dio.get('/api/referrals/my-code/');
    return ReferralData.fromJson(response.data);
  }

  Future<Map<String, dynamic>> claimCode(String code) async {
    final response = await _dio.post(
      '/api/referrals/claim/',
      data: {'referral_code': code},
    );
    return response.data;
  }
}

final referralRepositoryProvider = Provider(
  (ref) => ReferralRepository(ref.watch(dioProvider)),
);

// --- PROVIDERS ---
final referralDataProvider = FutureProvider.autoDispose<ReferralData>((
  ref,
) async {
  return ref.watch(referralRepositoryProvider).getMyReferral();
});

// StateNotifier to handle the claiming process and loading state
class ClaimReferralNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  ClaimReferralNotifier(this._ref) : super(const AsyncData(null));

  Future<void> claim(String code) async {
    state = const AsyncLoading();
    try {
      await _ref.read(referralRepositoryProvider).claimCode(code);
      state = const AsyncData(null);

      // Refresh the referral page stats and the global subscription limits!
      _ref.invalidate(referralDataProvider);
      _ref.invalidate(mySubscriptionProvider);
    } catch (e) {
      String errorMsg = "An error occurred";
      if (e is DioException && e.response?.data != null) {
        errorMsg = e.response?.data['error'] ?? errorMsg;
      }
      state = AsyncError(errorMsg, StackTrace.current);
    }
  }
}

final claimReferralProvider =
    StateNotifierProvider.autoDispose<ClaimReferralNotifier, AsyncValue<void>>((
      ref,
    ) {
      return ClaimReferralNotifier(ref);
    });
