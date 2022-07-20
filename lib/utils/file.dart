import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:disk_space/disk_space.dart';
import 'package:root/root.dart';

class FileCached {
  FileCached(this.file, {this.basepath})
      : shortpath = File(getRelativePath(basepath, file));

  final File file;
  final Directory? basepath;
  final File shortpath;
  int? lengthCache;

  File get absolute => file.absolute;
  String get path => file.path;

  Future<int> length() async => lengthCache ??= await file.length();
  int lengthSync() => lengthCache ??= file.lengthSync();
}

Future<bool> isSpaceEnoughFor(
  final String filepath,
  final String dstFolder,
) async {
  final freeSpace =
      (await DiskSpace.getFreeDiskSpaceForPath(dstFolder))! * 1024;

  final dbSize = int.parse(
    RegExp(r'(\d+)').stringMatch((await Root.exec(cmd: 'du $filepath'))!)!,
  );

  return freeSpace > dbSize;
}

Future<void> copy(File src, File dst) async {
  await Root.exec(cmd: 'cp ${src.absolute.path} ${dst.absolute.path}');
  final ownership = ((await Process.run(
              'stat', ['-c', '%U:%G', dst.absolute.parent.path],
              stdoutEncoding: utf8))
          .stdout as String)
      .trim()
      .split(':');
  await Root.exec(cmd: 'chown ${ownership[0]} ${dst.absolute.path}');
  await Root.exec(cmd: 'chgrp ${ownership[1]} ${dst.absolute.path}');
}

String formatBytes(int bytes) {
  if (bytes <= 0) return "0 B";
  const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
  var i = (log(bytes) / log(1024)).floor();
  return '${(bytes / pow(1024, i)).toStringAsFixed(2)} ${suffixes[i]}';
}

String getRelativePath(Directory? basepath, File file) =>
    file.absolute.path.substring(basepath?.absolute.path.length ?? 0);
