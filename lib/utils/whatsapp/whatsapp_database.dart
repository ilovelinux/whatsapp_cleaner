import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:root/root.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class WhatsAppDatabase {
  WhatsAppDatabase._(this.path);

  final File path;
  late final Database _database;

  static Future<WhatsAppDatabase> open(final File db) async {
    final waDB = WhatsAppDatabase._(db);
    await waDB._open();
    return waDB;
  }

  Future<void> _open() async {
    if (Platform.isAndroid) {
      _database = await openReadOnlyDatabase(path.absolute.path);
    } else {
      _database = await databaseFactoryFfi.openDatabase(path.absolute.path);
    }
  }

  Future<List<Map<String, Object?>>> getMedia({
    final bool getHash = false,
  }) =>
      _database.query(
        'message_media',
        columns: ['file_path', if (getHash) 'file_hash'],
        where: 'file_path IS NOT NULL',
      );
}
