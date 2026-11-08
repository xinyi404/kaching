import 'background_sync_stub.dart'
    if (dart.library.io) 'background_sync_native.dart' as platform;

Future<void> initializeBackgroundSync() => platform.initializeBackgroundSync();

Future<void> enqueuePendingSync() => platform.enqueuePendingSync();
