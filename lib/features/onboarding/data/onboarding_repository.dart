import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// `GET /onboarding`: the first-time setup checklist, worked out from the landlord's data.
class Onboarding {
  const Onboarding({
    required this.steps,
    required this.doneCount,
    required this.total,
    required this.completed,
    required this.dismissed,
    this.firstLeaseId,
  });

  factory Onboarding.fromJson(Map<String, dynamic> j) => Onboarding(
    steps: [
      for (final s in j['steps'] as List<dynamic>)
        (
          key: (s as Map<String, dynamic>)['key'] as String,
          done: s['done'] as bool,
          optional: s['optional'] as bool? ?? false,
        ),
    ],
    doneCount: j['done_count'] as int,
    total: j['total'] as int,
    completed: j['completed'] as bool,
    dismissed: j['dismissed'] as bool,
    firstLeaseId: j['first_lease_id'] as int?,
  );

  final List<({String key, bool done, bool optional})> steps;
  final int doneCount;
  final int total;
  final bool completed;
  final bool dismissed;
  final int? firstLeaseId;

  /// Show the Home card until everything required is done or it was hidden.
  bool get showOnHome => !completed && !dismissed;
}

class OnboardingRepository {
  OnboardingRepository(this._api);

  final ApiClient _api;

  Future<Onboarding> get() async {
    final data = await _api.get('/onboarding') as Map<String, dynamic>;
    return Onboarding.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<Onboarding> dismiss() async {
    final data = await _api.post('/onboarding/dismiss') as Map<String, dynamic>;
    return Onboarding.fromJson(data['data'] as Map<String, dynamic>);
  }
}

final onboardingRepositoryProvider = Provider<OnboardingRepository>(
  (ref) => OnboardingRepository(ref.watch(apiClientProvider)),
);

final onboardingProvider = FutureProvider.autoDispose<Onboarding>(
  (ref) => ref.watch(onboardingRepositoryProvider).get(),
);
