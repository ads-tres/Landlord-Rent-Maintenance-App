import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

class Bank {
  const Bank({required this.id, required this.name});

  factory Bank.fromJson(Map<String, dynamic> j) =>
      Bank(id: j['id'] as String, name: j['name'] as String);

  final String id;
  final String name;
}

/// The landlord's payout bank account (a Chapa sub-account). The number comes back masked.
class PayoutAccount {
  const PayoutAccount({
    required this.bankCode,
    required this.accountName,
    required this.accountNumber,
    required this.status,
    this.bankName,
  });

  factory PayoutAccount.fromJson(Map<String, dynamic> j) => PayoutAccount(
    bankCode: j['bank_code'] as String,
    bankName: j['bank_name'] as String?,
    accountName: j['account_name'] as String,
    accountNumber: j['account_number'] as String,
    status: j['status'] as String,
  );

  final String bankCode;
  final String? bankName;
  final String accountName;
  final String accountNumber;

  /// active | pending | failed
  final String status;

  bool get isActive => status == 'active';
}

class OnlineRentRepository {
  OnlineRentRepository(this._api);

  final ApiClient _api;

  Future<List<Bank>> banks() async =>
      ((await _api.get('/chapa/banks') as Map<String, dynamic>)['data']
              as List<dynamic>)
          .map((b) => Bank.fromJson(b as Map<String, dynamic>))
          .toList();

  Future<PayoutAccount?> payoutAccount() async {
    final data =
        (await _api.get('/payout-account') as Map<String, dynamic>)['data'];
    return data == null
        ? null
        : PayoutAccount.fromJson(data as Map<String, dynamic>);
  }

  Future<PayoutAccount> savePayoutAccount({
    required String bankCode,
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    final data = await _api.put(
      '/payout-account',
      data: {
        'bank_code': bankCode,
        'bank_name': bankName,
        'account_name': accountName,
        'account_number': accountNumber,
      },
    ) as Map<String, dynamic>;
    return PayoutAccount.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> setEnabled(bool enabled) =>
      _api.patch('/auth/me', data: {'online_rent_enabled': enabled});

  Future<void> sendPayLink(int leaseId) =>
      _api.post('/leases/$leaseId/pay-link/send');
}

final onlineRentRepositoryProvider = Provider<OnlineRentRepository>(
  (ref) => OnlineRentRepository(ref.watch(apiClientProvider)),
);

final payoutAccountProvider = FutureProvider.autoDispose<PayoutAccount?>(
  (ref) => ref.watch(onlineRentRepositoryProvider).payoutAccount(),
);

final banksProvider = FutureProvider.autoDispose<List<Bank>>(
  (ref) => ref.watch(onlineRentRepositoryProvider).banks(),
);
