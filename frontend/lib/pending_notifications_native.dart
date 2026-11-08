import 'dart:convert';

import 'database_helper.dart';

Future<void> storePendingNotification({
  required String packageName,
  required String title,
  required String text,
  required DateTime createdAt,
}) async {
  await DatabaseHelper.instance.insertPendingNotification(
    packageName: packageName,
    content: jsonEncode({'title': title, 'text': text}),
    createdAt: createdAt,
  );
}
