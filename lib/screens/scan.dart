import 'package:file_icon/file_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:whatsapp_cleaner/screens/settings.dart';

import '../bloc/scan_bloc.dart';
import '../utils/file.dart';

class ScanPage extends StatelessWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("WhatsApp Cleaner"),
        actions: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Icon(Icons.settings),
            ),
          )
        ],
      ),
      body: const _ScanView(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.replay),
        onPressed: () => context.read<ScanBloc>().add(const ScanEvent()),
      ),
      bottomNavigationBar: BlocBuilder<ScanBloc, ScanState>(
        builder: (context, state) => state.maybeWhen(
          success: (files) {
            final formatSize = formatBytes(
              files
                  .map((e) => e.lengthSync())
                  .reduce((value, element) => value + element),
            );

            return BottomAppBar(
              child: TextButton(
                onPressed: () => null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Clean all ($formatSize)"),
                ),
              ),
            );
          },
          orElse: () => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ScanView extends StatelessWidget {
  const _ScanView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Theme.of(context).secondaryHeaderColor,
          child: BlocBuilder<ScanBloc, ScanState>(
            builder: (context, state) => state.when(
              initial: () => const Text("Initial"),
              loading: (info) => Text(info),
              progressLoading: (String info, int count, int total) =>
                  Text("$count/$total: $info"),
              success: (files) => Text("Done: ${files.length}"),
              error: (error) => Text(error),
            ),
          ),
        ),
        BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) => state.maybeWhen(
            loading: (info) => const LinearProgressIndicator(),
            progressLoading: (_, int count, int total) =>
                LinearProgressIndicator(value: total / count),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
        BlocBuilder<ScanBloc, ScanState>(
          builder: (context, state) => state.maybeWhen(
            success: (files) => _ScanList(List.from(files)
              ..sort(((a, b) => b.lengthSync().compareTo(a.lengthSync())))),
            orElse: () => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _ScanList extends StatelessWidget {
  const _ScanList(this.files);

  final List<FileCached> files;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        itemCount: files.length,
        itemBuilder: (BuildContext context, int index) => ListTile(
          title: Text(files[index].path),
          subtitle: Text(formatBytes(files[index].lengthSync())),
          leading: FutureBuilder(
            future: _filePreview(files[index]),
            builder: (context, AsyncSnapshot<Widget?> snapshot) =>
                snapshot.data ?? const CircularProgressIndicator(),
          ),
          onTap: () async => await OpenFile.open(files[index].path),
        ),
      ),
    );
  }

  Future<Widget> _filePreview(FileCached file) async {
    switch (extension(file.path)) {
      case '.jpeg':
      case '.jpg':
        return Image.file(file.file);
      case '.3gp':
      case '.mp4':
      case '.webgp':
        return Image.memory(
            (await VideoThumbnail.thumbnailData(video: file.path))!);
      default:
        return FileIcon(basename(file.path));
    }
  }
}
