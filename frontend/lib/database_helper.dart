// frontend/lib/database_helper.dart
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static const _databaseName = 'personal_finance.db';
  static const _databaseVersion = 1;
  static const pendingTable = 'pending_transactions';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final directory = await getApplicationDocumentsDirectory();
    final dbPath = path.join(directory.path, _databaseName);
    _database = await openDatabase(
      dbPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $pendingTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            package_name TEXT NOT NULL,
            content TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_pending_created_at ON $pendingTable(created_at)',
        );
      },
    );
    return _database!;
  }

  Future<int> insertPendingNotification({
    required String packageName,
    required String content,
    required DateTime createdAt,
  }) async {
    final db = await database;
    final existing = await db.query(
      pendingTable,
      where: 'package_name = ? AND content = ?',
      whereArgs: [packageName, content],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }
    return db.insert(pendingTable, {
      'package_name': packageName,
      'content': content,
      'created_at': createdAt.toUtc().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getPendingNotifications({int limit = 100}) async {
    final db = await database;
    return db.query(
      pendingTable,
      orderBy: 'id ASC',
      limit: limit,
    );
  }

  Future<void> deletePendingNotifications(List<int> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.delete(
      pendingTable,
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );
  }
}
