import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/data/app_database.dart';
import '../../../core/models/paper.dart';

final papersRepositoryProvider =
    Provider((ref) => PapersRepository(ref.watch(appDatabaseProvider)));

/// Built-in papers first, then the ones the user added, oldest first.
final papersProvider = FutureProvider<List<Paper>>((ref) async {
  final saved = await ref.watch(papersRepositoryProvider).all();
  return [...builtInPapers, ...saved];
});

class PapersRepository {
  PapersRepository(this._db);

  final AppDatabase _db;

  Future<List<Paper>> all() async {
    final db = await _db.database;
    final rows = await db.query('papers', orderBy: 'created_at ASC');
    return rows.map(Paper.fromMap).toList();
  }

  /// Inserts a new paper or updates an existing one with the same id.
  Future<void> save(Paper paper) async {
    final db = await _db.database;
    final updated = await db.update('papers', paper.toMap(),
        where: 'id = ?', whereArgs: [paper.id]);
    if (updated == 0) {
      await db.insert(
        'papers',
        {...paper.toMap(), 'created_at': DateTime.now().millisecondsSinceEpoch},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('papers', where: 'id = ?', whereArgs: [id]);
  }
}
