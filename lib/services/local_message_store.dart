import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class LocalMessageStore {
  static Database? _database;
  static const String _tableName = 'decrypted_messages';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String path = join(await getDatabasesPath(), 'bharatconnect_messages.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE $_tableName(messageId TEXT PRIMARY KEY, decryptedText TEXT)",
        );
      },
    );
  }

  Future<void> saveDecryptedMessage(String messageId, String decryptedText) async {
    final db = await database;
    await db.insert(
      _tableName,
      {'messageId': messageId, 'decryptedText': decryptedText},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    debugPrint('LocalMessageStore: Saved message $messageId');
  }

  Future<String?> getDecryptedMessage(String messageId) async {
    final db = await database;
    List<Map<String, dynamic>> results = await db.query(
      _tableName,
      columns: ['decryptedText'],
      where: 'messageId = ?',
      whereArgs: [messageId],
    );
    if (results.isNotEmpty) {
      debugPrint('LocalMessageStore: Retrieved message $messageId from local store.');
      return results.first['decryptedText'] as String;
    }
    debugPrint('LocalMessageStore: Message $messageId not found in local store.');
    return null;
  }
}