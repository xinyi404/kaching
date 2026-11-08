// frontend/lib/sync_service.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';

import 'api_service.dart';
import 'database_helper.dart';

const syncTaskName = 'sync_pending_transactions';
bool _isSyncing = false;

Future<int> syncPendingNotifications() async {
  if (_isSyncing) {
    debugPrint('[SyncService] Sync already in progress, skipping duplicate call');
    return 0;
  }
  _isSyncing = true;
  try {
    final rows = await DatabaseHelper.instance.getPendingNotifications();
    debugPrint('[SyncService] Found ${rows.length} pending notifications in queue');
    if (rows.isEmpty) return 0;

    final payload = rows.map((row) {
      final stored =
          jsonDecode(row['content']! as String) as Map<String, dynamic>;
      return <String, String>{
        'package_name': row['package_name']! as String,
        'title': stored['title'] as String? ?? '',
        'text': stored['text'] as String? ?? '',
      };
    }).toList(growable: false);

    final syncUrl = '$apiBaseUrl/api/v1/transactions/sync';
    debugPrint('[SyncService] Sending ${payload.length} items to $syncUrl');
    final response = await http
        .post(
          Uri.parse(syncUrl),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    debugPrint('[SyncService] Response: ${response.statusCode} - ${response.body}');
    if (response.statusCode >= 200 && response.statusCode < 300) {
      await DatabaseHelper.instance.deletePendingNotifications(
        rows.map((row) => row['id']! as int).toList(growable: false),
      );
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return decoded['saved'] as int? ?? 0;
      } catch (_) {
        return 0;
      }
    }
    return 0;
  } catch (e, st) {
    debugPrint('[SyncService] Sync exception: $e\n$st');
    return 0;
  } finally {
    _isSyncing = false;
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    if (task != syncTaskName) return true;
    final saved = await syncPendingNotifications();
    return saved >= 0;
  });
}

Future<void> enqueuePendingSync() async {
  // 1. Attempt immediate sync in foreground
  unawaited(syncPendingNotifications());

  // 2. Schedule WorkManager task as reliable background fallback
  try {
    await Workmanager().registerOneOffTask(
      'sync-${DateTime.now().millisecondsSinceEpoch}',
      syncTaskName,
      constraints: Constraints(networkType: NetworkType.connected),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 1),
    );
  } catch (_) {}
}
