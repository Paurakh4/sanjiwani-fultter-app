import 'dart:convert';

import 'package:sqflite/sqflite.dart';

/// Offline mirror of what the server last gave us.
///
/// Every collection is stored as the record's own JSON, because the catalog is
/// a dumb cache here: the app renders it, never edits it, and re-fetching is
/// always available. Keeping the payloads opaque means adding a field to the
/// backend needs no migration in here.
class CacheDb {
  CacheDb._(this._db);

  final Database _db;

  static const _file = 'clinic_cache.db';
  static const _table = 'records';

  static Future<CacheDb> open() async {
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      '$dir/$_file',
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE $_table ('
          'collection TEXT NOT NULL, '
          'id TEXT NOT NULL, '
          'payload TEXT NOT NULL, '
          'PRIMARY KEY (collection, id))',
        );
      },
    );
    return CacheDb._(db);
  }

  Future<List<Map<String, dynamic>>> rows(String collection) async {
    final stored = await _db.query(
      _table,
      columns: ['payload'],
      where: 'collection = ?',
      whereArgs: [collection],
    );
    return stored
        .map((row) => jsonDecode(row['payload'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Replaces the whole collection so a row deleted on the server cannot
  /// linger here as something the patient still sees.
  Future<void> replace(String collection, List<Map<String, dynamic>> rows) async {
    final batch = _db.batch()..delete(_table, where: 'collection = ?', whereArgs: [collection]);
    for (final row in rows) {
      batch.insert(_table, {
        'collection': collection,
        'id': row['id'] as String? ?? '',
        'payload': jsonEncode(row),
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateOne(String collection, Map<String, dynamic> row) =>
      _db.insert(
        _table,
        {
          'collection': collection,
          'id': row['id'] as String? ?? '',
          'payload': jsonEncode(row),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> clear() => _db.delete(_table);

  Future<void> close() => _db.close();
}
