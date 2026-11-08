import 'pending_notifications_stub.dart'
    if (dart.library.io) 'pending_notifications_native.dart' as platform;

Future<void> storePendingNotification({
  required String packageName,
  required String title,
  required String text,
  required DateTime createdAt,
}) =>
    platform.storePendingNotification(
      packageName: packageName,
      title: title,
      text: text,
      createdAt: createdAt,
    );
