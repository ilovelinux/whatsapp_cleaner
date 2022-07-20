import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart';
import 'package:root/root.dart';
import 'package:root_access/root_access.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_cleaner/utils/whatsapp/whatsapp.dart';

import '../utils/file.dart';
import '../utils/whatsapp/whatsapp_database.dart';

part 'scan_event.dart';
part 'scan_state.dart';
part 'scan_bloc.freezed.dart';

class ScanBloc extends Bloc<ScanEvent, ScanState> {
  ScanBloc() : super(const ScanState.initial()) {
    on<ScanEvent>((event, emit) async {
      final prefs = await GetIt.I.getAsync<SharedPreferences>();
      try {
        final dbPath = File(join(prefs.getString('dbPath')!, 'msgstore.db'));
        final waPath = Directory(prefs.getString('waPath')!);

        if (Platform.isAndroid) {
          emit(const ScanState.loading("Asking for root access..."));
          final rootStatus = await RootAccess.requestRootAccess;
          if (!rootStatus) {
            emit(const ScanState.error("Root not allowed"));
            return;
          }
        }

        emit(const ScanState.loading("Copying the database..."));

        if (true) {
          await _closeWhatsApp();
        }
        final tmpdb = await WhatsApp.clonedb(dbPath);

        emit(const ScanState.loading("Opening the database..."));
        final whatsapp = await WhatsApp.getInstance(tmpdb.parent, waPath);

        emit(const ScanState.loading("Getting media from the database..."));
        final dbMedia = await whatsapp.getDatabaseMedia();

        emit(const ScanState.loading("Comparing files..."));
        var trashMedia = await whatsapp.findTrashFiles(
          dbMedia: dbMedia,
          waMedia: whatsapp.getWhatsAppMedia(),
        );

        emit(const ScanState.loading("Getting trash files size..."));
        await Future.wait(trashMedia.map((e) => e.length()));
        trashMedia =
            await Future.wait(trashMedia.map((e) => e.length().then((_) => e)))
              ..sort((a, b) => a.lengthSync().compareTo(b.lengthSync()));

        emit(const ScanState.loading("Sorting files by size..."));
        trashMedia = List<FileCached>.from(trashMedia)
          ..sort((a, b) => a.lengthSync().compareTo(b.lengthSync()));

        emit(ScanState.success(trashMedia));
      } catch (e) {
        emit(ScanState.error(e.toString()));
      }
    });
  }

  @override
  void onChange(Change<ScanState> change) {
    print(change);
    super.onChange(change);
  }
}

Future<void> _closeWhatsApp() async {
  final processList = await Root.exec(cmd: 'ps -A -oPID,CMD') ?? "";
  print(processList);
  final pid = RegExp(r"/(\d+)\s+com\.whatsapp/").firstMatch(processList);
  if (pid != null) {
    print("success");
    Process.killPid(int.parse(pid.group(1)!));
  }
}
