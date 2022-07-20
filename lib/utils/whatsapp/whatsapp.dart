import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:root/root.dart';
import 'package:whatsapp_cleaner/utils/file.dart';

import 'whatsapp_database.dart';

class WhatsApp {
  WhatsApp._(this.dbPath, this.waPath)
      : waMediaPath = Directory(join(waPath.absolute.path, 'Media')),
        msgstorePath = File(join(dbPath.absolute.path, 'msgstore.db'));

  final Directory dbPath;
  final Directory waPath;
  final Directory waMediaPath;

  final File msgstorePath;
  late final WhatsAppDatabase msgstore;

  static Future<WhatsApp> getInstance(
    final Directory dbPath,
    final Directory waPath,
  ) async {
    final wa = WhatsApp._(dbPath, waPath);
    await wa._init();
    return wa;
  }

  Future _init() async => msgstore = await WhatsAppDatabase.open(msgstorePath);

  static Future<File> clonedb(final File db) async {
    final tmpdst = (await getTemporaryDirectory()).absolute.path;
    final tmpdb = File(join(tmpdst, basename(db.path)));

    await (tmpdb.delete().catchError((_) => File('.')));

    if (!await isSpaceEnoughFor(db.absolute.path, tmpdb.absolute.parent.path)) {
      throw Exception("File space is not enough");
    }

    if (Platform.isAndroid) {
      await Root.exec(cmd: 'cp ${db.absolute.path} ${tmpdb.absolute.path}');
      final ownership = ((await Process.run(
                  'stat', ['-c', '%U:%G', tmpdb.absolute.parent.path],
                  stdoutEncoding: utf8))
              .stdout as String)
          .trim()
          .split(':');
      await Root.exec(cmd: 'chown ${ownership[0]} ${tmpdb.absolute.path}');
      await Root.exec(cmd: 'chgrp ${ownership[1]} ${tmpdb.absolute.path}');
    } else {
      await File(db.absolute.path).copy(tmpdb.absolute.path);
    }

    return tmpdb;
  }

  Future<List<Map<String, Object?>>> getDatabaseMedia() => msgstore.getMedia();

  Stream<File> getWhatsAppMedia() => waMediaPath
      .list(recursive: true)
      .where((event) => event is File && !basename(event.path).startsWith('.'))
      .cast<File>();

  Future<List<FileCached>> findTrashFiles({
    required final Stream<File> waMedia,
    required final List<Map<String, Object?>> dbMedia,
  }) {
    final dbMediaSet = dbMedia
        .map((e) => join(waPath.absolute.path, e['file_path'] as String))
        .toSet();

    return waMedia
        .where((e) => !dbMediaSet.contains(e.absolute.path))
        .map((event) => FileCached(event, basepath: waMediaPath))
        .toList();
  }
}
