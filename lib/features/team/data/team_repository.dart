import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// A caretaker on the landlord's team.
class TeamMember {
  const TeamMember({
    required this.id,
    required this.phone,
    this.name,
    this.joined = false,
  });

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
    id: j['id'] as int,
    phone: j['phone'] as String,
    name: j['name'] as String?,
    joined: j['joined'] as bool? ?? false,
  );

  final int id;
  final String phone;
  final String? name;

  /// Has logged in at least once.
  final bool joined;
}

class TeamRepository {
  TeamRepository(this._api);

  final ApiClient _api;

  Future<List<TeamMember>> list() async {
    final data = await _api.get('/team') as Map<String, dynamic>;
    return (data['data'] as List<dynamic>)
        .map((m) => TeamMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Adds a caretaker and texts them how to log in.
  Future<TeamMember> invite({
    required String name,
    required String phone,
  }) async {
    final data = await _api.post(
      '/team',
      data: {'name': name, 'phone': phone},
    ) as Map<String, dynamic>;
    return TeamMember.fromJson(data['data'] as Map<String, dynamic>);
  }

  /// Ends access at once; they are signed out everywhere.
  Future<void> remove(int id) => _api.delete('/team/$id');
}

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepository(ref.watch(apiClientProvider)),
);

final teamProvider = FutureProvider.autoDispose<List<TeamMember>>(
  (ref) => ref.watch(teamRepositoryProvider).list(),
);
