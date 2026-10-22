import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/app_database.dart';
import '../domain/saved_word.dart';

final wordsRepositoryProvider =
    Provider((ref) => WordsRepository(ref.watch(appDatabaseProvider)));

final savedWordsProvider = FutureProvider<List<SavedWord>>(
  (ref) => ref.watch(wordsRepositoryProvider).all(),
);

class WordsRepository {
  WordsRepository(this._db);

  final AppDatabase _db;

  Future<List<SavedWord>> all() async {
    final db = await _db.database;
    final rows = await db.query('saved_words', orderBy: 'created_at DESC');
    return rows.map(SavedWord.fromMap).toList();
  }

  Future<void> save(SavedWord word) async {
    final db = await _db.database;
    await db.insert('saved_words', word.toMap()..remove('id'));
  }

  Future<void> delete(int id) async {
    final db = await _db.database;
    await db.delete('saved_words', where: 'id = ?', whereArgs: [id]);
  }
}
