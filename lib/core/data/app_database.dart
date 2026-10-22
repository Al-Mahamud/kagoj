import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

final appDatabaseProvider = Provider((ref) => AppDatabase());

/// The app's single SQLite database (saved words + user-added papers).
class AppDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    return openDatabase(
      join(await getDatabasesPath(), 'kagoj.db'),
      version: 2,
      onCreate: (db, _) async {
        await _createSavedWords(db);
        await _createPapers(db);
      },
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) await _createPapers(db);
      },
    );
  }

  static Future<void> _createSavedWords(Database db) => db.execute('''
        CREATE TABLE saved_words (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          text TEXT NOT NULL,
          meaning TEXT NOT NULL,
          language TEXT NOT NULL,
          source TEXT NOT NULL,
          created_at INTEGER NOT NULL,
          is_sentence INTEGER NOT NULL DEFAULT 0
        )
      ''');

  static Future<void> _createPapers(Database db) => db.execute('''
        CREATE TABLE papers (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          url TEXT NOT NULL,
          language TEXT NOT NULL,
          created_at INTEGER NOT NULL
        )
      ''');
}
