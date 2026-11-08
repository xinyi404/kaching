import 'notification_capture_types.dart';

class NotificationCapture {
  Future<String> start(NotificationHandler onNotification) async =>
      'Notification capture is available on Android only';

  Future<void> checkActiveNotifications(NotificationHandler onNotification) async {}

  Future<void> dispose() async {}
}

NotificationCapture createNotificationCapture() => NotificationCapture();
