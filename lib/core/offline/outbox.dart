import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../storage/secure_store.dart';

const outboxKey = 'offline_outbox';

/// Random id the server uses to recognise a record sent more than once.
String newClientRef() {
  final r = Random.secure();
  return List.generate(
    16,
    (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// What was saved offline. Payments have their own queue (`PendingPayments`).
enum OutboxKind {
  expense('/expenses', 'photo'),
  repair('/maintenance', 'photos[]');

  const OutboxKind(this.path, this.photoField);

  final String path;
  final String photoField;

  static OutboxKind parse(String name) =>
      values.firstWhere((k) => k.name == name);
}

/// An expense or repair logged without a connection, waiting to be sent.
class OutboxItem {
  const OutboxItem({
    required this.kind,
    required this.clientRef,
    required this.fields,
    required this.title,
    required this.createdAt,
    this.subtitle,
    this.photos = const [],
    this.lastError,
  });

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    kind: OutboxKind.parse(j['kind'] as String),
    clientRef: j['client_ref'] as String,
    fields: (j['fields'] as Map<String, dynamic>),
    title: j['title'] as String,
    subtitle: j['subtitle'] as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
    photos: (j['photos'] as List<dynamic>? ?? const []).cast<String>(),
    lastError: j['last_error'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'client_ref': clientRef,
    'fields': fields,
    'title': title,
    'subtitle': subtitle,
    'created_at': createdAt.toIso8601String(),
    'photos': photos,
    'last_error': lastError,
  };

  OutboxItem withError(String? error) =>
      OutboxItem.fromJson({...toJson(), 'last_error': error});

  OutboxItem withPhotos(List<String> paths) =>
      OutboxItem.fromJson({...toJson(), 'photos': paths});

  final OutboxKind kind;
  final String clientRef;

  /// The form fields as the API takes them (amounts in santim, dates as Y-m-d).
  final Map<String, dynamic> fields;

  /// Shown in the "waiting to sync" list, e.g. "Leaking tap · Unit 3".
  final String title;
  final String? subtitle;
  final DateTime createdAt;

  /// Copies kept in the app's own folder, so the camera's temp files can go.
  final List<String> photos;

  /// Set when the server refused it, so it needs the landlord.
  final String? lastError;
}

/// Keeps photos for queued items until they are sent. Swapped out in tests.
class OutboxFiles {
  Future<String> keep(String path) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}/outbox');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final name =
        '${DateTime.now().microsecondsSinceEpoch}-${path.split('/').last}';
    return (await File(path).copy('${dir.path}/$name')).path;
  }

  Future<void> remove(List<String> paths) async {
    for (final p in paths) {
      final f = File(p);
      if (f.existsSync()) await f.delete();
    }
  }
}

final outboxFilesProvider = Provider<OutboxFiles>((ref) => OutboxFiles());

/// Expenses and repairs saved on the phone while offline. Sent oldest first together
/// with pending payments (app start, back to the foreground, "Sync now").
/// Each carries a client_ref, so sending twice never creates two records.
class Outbox extends AsyncNotifier<List<OutboxItem>> {
  bool _syncing = false;

  @override
  Future<List<OutboxItem>> build() async {
    final raw = await ref.read(keyValueStoreProvider).read(outboxKey);
    if (raw == null) return [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((i) => OutboxItem.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(List<OutboxItem> items) async {
    state = AsyncData(items);
    await ref
        .read(keyValueStoreProvider)
        .write(
          outboxKey,
          items.isEmpty
              ? null
              : jsonEncode(items.map((i) => i.toJson()).toList()),
        );
  }

  Future<void> add(OutboxItem item) async {
    final files = ref.read(outboxFilesProvider);
    final kept = [for (final p in item.photos) await files.keep(p)];
    await _save([...await future, item.withPhotos(kept)]);
  }

  Future<void> discard(String clientRef) async {
    final items = [...await future];
    final gone = items.where((i) => i.clientRef == clientRef).toList();
    await _save(items..removeWhere((i) => i.clientRef == clientRef));
    for (final i in gone) {
      await ref.read(outboxFilesProvider).remove(i.photos);
    }
  }

  /// Returns how many items were sent.
  Future<int> sync() async {
    if (_syncing) return 0;
    _syncing = true;
    var sent = 0;
    try {
      final items = [...await future];
      final api = ref.read(apiClientProvider);

      for (final item in [...items]) {
        try {
          final photos = [
            for (final p in item.photos)
              if (File(p).existsSync()) await MultipartFile.fromFile(p),
          ];
          await api.post(
            item.kind.path,
            data: FormData.fromMap({
              ...item.fields,
              'client_ref': item.clientRef,
              if (photos.isNotEmpty)
                item.kind.photoField: item.kind == OutboxKind.expense
                    ? photos.first
                    : photos,
            }),
          );
          items.removeWhere((i) => i.clientRef == item.clientRef);
          await ref.read(outboxFilesProvider).remove(item.photos);
          sent++;
        } on ApiException catch (e) {
          if (e.isNetworkError) break; // still offline: try again later
          final index = items.indexWhere((i) => i.clientRef == item.clientRef);
          items[index] = item.withError(
            e.fieldErrors.values.firstOrNull ?? e.message,
          );
        }
      }

      await _save(items);
      if (sent > 0) ref.read(outboxSyncedProvider.notifier).bump();
      return sent;
    } finally {
      _syncing = false;
    }
  }
}

/// Goes up each time queued items reach the server; expense and repair lists
/// watch it so they show the new records.
class OutboxSynced extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final outboxSyncedProvider = NotifierProvider<OutboxSynced, int>(
  OutboxSynced.new,
);

final outboxProvider = AsyncNotifierProvider<Outbox, List<OutboxItem>>(
  Outbox.new,
);
