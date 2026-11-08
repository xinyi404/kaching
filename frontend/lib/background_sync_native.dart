import 'package:workmanager/workmanager.dart';

import 'sync_service.dart' as sync;

Future<void> initializeBackgroundSync() =>
    Workmanager().initialize(sync.callbackDispatcher);

Future<void> enqueuePendingSync() => sync.enqueuePendingSync();
