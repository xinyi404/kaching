import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:notification_listener_service/notification_event.dart';

import 'notification_capture_types.dart';

class NotificationCapture {
  StreamSubscription<ServiceNotificationEvent>? _subscription;

  Future<void> checkActiveNotifications(NotificationHandler onNotification) async {
    try {
      const channel = MethodChannel('x-slayer/notifications_channel');
      final List<dynamic>? active =
          await channel.invokeMethod<List<dynamic>>('getActiveNotifications');
      if (active == null) return;
      debugPrint('[NotificationCapture] Scanned ${active.length} active notifications in drawer');
      for (final item in active) {
        if (item is! Map) continue;
        final packageName = item['packageName'] as String?;
        if (packageName == null || packageName.isEmpty) continue;
        final title = item['title'] as String? ?? '';
        final content = item['content'] as String? ?? '';
        debugPrint('[NotificationCapture] Drawer notification: $packageName - $title - $content');
        await onNotification(packageName, title, content);
      }
    } catch (e, st) {
      debugPrint('[NotificationCapture] Failed to getActiveNotifications: $e\n$st');
    }
  }

  Future<String> start(NotificationHandler onNotification) async {
    var granted = await NotificationListenerService.isPermissionGranted();
    debugPrint('[NotificationCapture] isPermissionGranted: $granted');
    if (!granted) {
      granted = await NotificationListenerService.requestPermission();
    }
    if (!granted) return 'Notification access not granted';

    // Check existing notifications in the status bar
    await checkActiveNotifications(onNotification);

    _subscription =
        NotificationListenerService.notificationsStream.listen((event) async {
      debugPrint('[NotificationCapture] Live event: ${event.packageName} - ${event.title} - ${event.content}');
      if (event.hasRemoved == true) return;
      final packageName = event.packageName;
      if (packageName == null || packageName.isEmpty) return;
      await onNotification(
        packageName,
        event.title ?? '',
        event.content ?? '',
      );
    });
    return 'Notification access granted';
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}

NotificationCapture createNotificationCapture() => NotificationCapture();
