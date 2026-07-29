import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// --- MODELS ---
class InvoiceModel {
  final String id;
  final String invoiceNumber;
  final String planName;
  final String amount;
  final String currency;
  final String status;
  final String createdAt;

  InvoiceModel({
    required this.id,
    required this.invoiceNumber,
    required this.planName,
    required this.amount,
    required this.currency,
    required this.status,
    required this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      id: json['id'] ?? '',
      invoiceNumber: json['invoice_number'] ?? '',
      planName: json['plan_name'] ?? '',
      amount: json['amount'] ?? '0.00',
      currency: json['currency'] ?? 'USD',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class CurrentPlanModel {
  final String name;
  final String price;
  final String duration;
  final String status;
  final bool isActive;
  final String? currentPeriodEnd;

  CurrentPlanModel({
    required this.name,
    required this.price,
    required this.duration,
    required this.status,
    required this.isActive,
    this.currentPeriodEnd,
  });

  factory CurrentPlanModel.fromJson(Map<String, dynamic> json) {
    return CurrentPlanModel(
      name: json['name'] ?? 'Free',
      price: json['price'] ?? '0.00',
      duration: json['duration'] ?? '/month',
      status: json['status'] ?? '',
      isActive: json['is_active'] ?? false,
      currentPeriodEnd: json['current_period_end'],
    );
  }
}

class BillingOverviewModel {
  final CurrentPlanModel currentPlan;
  final List<InvoiceModel> recentInvoices;

  BillingOverviewModel({
    required this.currentPlan,
    required this.recentInvoices,
  });

  factory BillingOverviewModel.fromJson(Map<String, dynamic> json) {
    return BillingOverviewModel(
      currentPlan: CurrentPlanModel.fromJson(json['current_plan'] ?? {}),
      recentInvoices: (json['recent_invoices'] as List?)
              ?.map((i) => InvoiceModel.fromJson(i))
              .toList() ??
          [],
    );
  }
}

// --- REPOSITORY ---
class BillingRepository {
  final Dio _dio;
  BillingRepository(this._dio);

  Future<BillingOverviewModel> getOverview() async {
    final response = await _dio.get('/api/billing/overview/');
    return BillingOverviewModel.fromJson(response.data);
  }
}

final billingRepositoryProvider = Provider(
  (ref) => BillingRepository(ref.watch(dioProvider)),
);

// --- PROVIDER ---
final billingOverviewProvider =
    FutureProvider.autoDispose<BillingOverviewModel>((ref) async {
  final repository = ref.watch(billingRepositoryProvider);
  return await repository.getOverview();
});