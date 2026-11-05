import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/storage/secure_store.dart';
import '../../../core/utils/dates.dart';
import '../../leases/data/leases_repository.dart';
import '../../rent/presentation/rent_screen.dart';
import '../data/payments_repository.dart';
import '../domain/payment.dart';

const pendingPaymentsKey = 'pending_payments';

/// Random id the server uses to recognise a payment sent more than once.
String newClientRef() {
  final r = Random.secure();
  return List.generate(
    16,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// A payment logged without a connection, waiting to be sent. Amounts in santim.
class PendingPayment {
  const PendingPayment({
    required this.clientRef,
    required this.leaseId,
    required this.amount,
    required this.paidAt,
    required this.method,
    this.reference,
    this.notes,
    this.sendSms = true,
    this.tenantName,
    this.unitLabel,
    this.lastError,
  });

  factory PendingPayment.fromJson(Map<String, dynamic> j) => PendingPayment(
    clientRef: j['client_ref'] as String,
    leaseId: j['lease_id'] as int,
    amount: j['amount'] as int,
    paidAt: parseYmd(j['paid_at'] as String),
    method: PaymentMethod.parse(j['method'] as String?),
    reference: j['reference'] as String?,
    notes: j['notes'] as String?,
    sendSms: j['send_sms'] as bool? ?? true,
    tenantName: j['tenant_name'] as String?,
    unitLabel: j['unit_label'] as String?,
    lastError: j['last_error'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'client_ref': clientRef,
    'lease_id': leaseId,
    'amount': amount,
    'paid_at': ymd(paidAt),
    'method': method.name,
    'reference': reference,
    'notes': notes,
    'send_sms': sendSms,
    'tenant_name': tenantName,
    'unit_label': unitLabel,
    'last_error': lastError,
  };

  PendingPayment withError(String? error) =>
      PendingPayment.fromJson({...toJson(), 'last_error': error});

  final String clientRef;
  final int leaseId;
  final int amount;
  final DateTime paidAt;
  final PaymentMethod method;
  final String? reference;
  final String? notes;
  final bool sendSms;
  final String? tenantName;
  final String? unitLabel;

  /// Set when the server refused it (e.g. a reference already used), so it needs the landlord.
  final String? lastError;
}

/// Payments saved on the phone while offline. Sent oldest first on app start, when the
/// app comes back to the foreground, on pull-to-refresh and from the "Sync now" banner.
/// Each carries a client_ref, so sending twice never creates two payments.
class PendingPayments extends AsyncNotifier<List<PendingPayment>> {
  bool _syncing = false;

  @override
  Future<List<PendingPayment>> build() async {
    final raw = await ref.read(keyValueStoreProvider).read(pendingPaymentsKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((p) => PendingPayment.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<PendingPayment> items) async {
    state = AsyncData(items);
    await ref
        .read(keyValueStoreProvider)
        .write(
          pendingPaymentsKey,
          items.isEmpty
              ? null
              : jsonEncode(items.map((p) => p.toJson()).toList()),
        );
  }

  Future<void> add(PendingPayment payment) async {
    final items = [...await future, payment];
    await _save(items);
  }

  Future<void> discard(String clientRef) async {
    await _save(
      [...await future]..removeWhere((p) => p.clientRef == clientRef),
    );
  }

  /// Returns how many payments were sent.
  Future<int> sync() async {
    if (_syncing) return 0;
    _syncing = true;
    var sent = 0;
    try {
      final items = [...await future];
      final repo = ref.read(paymentsRepositoryProvider);

      for (final p in [...items]) {
        try {
          await repo.create(
            leaseId: p.leaseId,
            amount: p.amount,
            paidAt: p.paidAt,
            method: p.method,
            reference: p.reference,
            notes: p.notes,
            sendSms: p.sendSms,
            clientRef: p.clientRef,
          );
          items.removeWhere((i) => i.clientRef == p.clientRef);
          sent++;
          ref.invalidate(leaseProvider(p.leaseId));
          ref.invalidate(leaseChargesProvider(p.leaseId));
          ref.invalidate(leasePaymentsProvider(p.leaseId));
        } on ApiException catch (e) {
          if (e.isNetworkError) break; // still offline: try again later
          final index = items.indexWhere((i) => i.clientRef == p.clientRef);
          items[index] = p.withError(
            e.fieldErrors.values.firstOrNull ?? e.message,
          );
        }
      }

      await _save(items);
      if (sent > 0) {
        ref.invalidate(monthChargesProvider);
        ref.invalidate(dashboardProvider);
      }
      return sent;
    } finally {
      _syncing = false;
    }
  }
}

final pendingPaymentsProvider =
    AsyncNotifierProvider<PendingPayments, List<PendingPayment>>(
      PendingPayments.new,
    );
