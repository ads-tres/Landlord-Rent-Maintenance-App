import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/utils/dates.dart';
import '../domain/dashboard_summary.dart';
import '../domain/payment.dart';

/// Amounts are sent and received in santim.
class PaymentsRepository {
  PaymentsRepository(this._api);

  final ApiClient _api;

  Future<Payment> create({
    required int leaseId,
    required int amount,
    required DateTime paidAt,
    required PaymentMethod method,
    String? reference,
    String? notes,
    bool sendSms = true,
    String? clientRef,
  }) async {
    final data = await _api.post(
      '/payments',
      data: {
        'lease_id': leaseId,
        'amount': amount,
        'paid_at': ymd(paidAt),
        'method': method.name,
        if (reference != null && reference.isNotEmpty) 'reference': reference,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'send_sms': sendSms,
        'client_ref': ?clientRef,
      },
    ) as Map<String, dynamic>;
    return Payment.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<List<Payment>> forLease(int leaseId) async {
    final data = await _api.get(
      '/payments',
      query: {'lease_id': leaseId},
    ) as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((p) => Payment.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> remove(int paymentId) => _api.delete('/payments/$paymentId');

  Future<DashboardSummary> dashboard() async {
    final data = await _api.get('/dashboard') as Map<String, dynamic>;
    return DashboardSummary.fromJson(data['data'] as Map<String, dynamic>);
  }
}

final paymentsRepositoryProvider = Provider<PaymentsRepository>(
  (ref) => PaymentsRepository(ref.watch(apiClientProvider)),
);

final leasePaymentsProvider = FutureProvider.autoDispose
    .family<List<Payment>, int>(
      (ref, leaseId) => ref.watch(paymentsRepositoryProvider).forLease(leaseId),
    );

final dashboardProvider = FutureProvider.autoDispose<DashboardSummary>(
  (ref) => ref.watch(paymentsRepositoryProvider).dashboard(),
);
