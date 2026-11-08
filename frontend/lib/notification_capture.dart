import 'notification_capture_stub.dart'
    if (dart.library.io) 'notification_capture_native.dart' as platform;

import 'notification_capture_types.dart';

class NotificationCapture {
  final platform.NotificationCapture _implementation =
      platform.createNotificationCapture();

  Future<String> start(NotificationHandler onNotification) =>
      _implementation.start(onNotification);

  Future<void> checkActiveNotifications(NotificationHandler onNotification) =>
      _implementation.checkActiveNotifications(onNotification);

  Future<void> dispose() => _implementation.dispose();
}
