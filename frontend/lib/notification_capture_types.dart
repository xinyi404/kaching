typedef NotificationHandler = Future<void> Function(
  String packageName,
  String title,
  String text,
);
