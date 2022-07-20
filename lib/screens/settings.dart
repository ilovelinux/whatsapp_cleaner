import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Padding(
            padding: EdgeInsets.all(16.0),
            child: Icon(Icons.arrow_back_rounded),
          ),
        ),
      ),
      body: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView({Key? key}) : super(key: key);

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  String _dbPath = "/data/data/com.whatsapp/databases/";
  String _waPath = "";
  bool _checkHash = false;

  @override
  void initState() {
    _loadSettings();
    super.initState();
  }

  Future<void> _loadSettings() async {
    final prefs = await GetIt.I.getAsync<SharedPreferences>();

    if (Platform.isAndroid) {
      final androidDeviceInfo = await DeviceInfoPlugin().androidInfo;
      _waPath = androidDeviceInfo.version.sdkInt! >= 30
          ? '/storage/emulated/0/Android/media/com.whatsapp/WhatsApp'
          : '/storage/emulated/0/WhatsApp';
    }

    setState(() {
      _dbPath = prefs.getString('dbPath') ?? _dbPath;
      _waPath = prefs.getString('waPath') ?? _waPath;
      _checkHash = prefs.getBool('checkHash') ?? _checkHash;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SettingsList(
      sections: [
        SettingsSection(
          title: const Text('Settings'),
          tiles: [
            SettingsTile(
              title: const Text("Database path"),
              value: Text(_dbPath),
              onPressed: (context) async {
                final newPath = await _showPreferenceDialog(
                  dialog: _InputDialog("Database path", text: _dbPath),
                  key: 'dbPath',
                );
                setState(() => _dbPath = newPath ?? _dbPath);
              },
            ),
            SettingsTile(
              title: const Text("WhatsApp path"),
              value: Text(_waPath),
              onPressed: (context) async {
                final newPath = await FilePicker.platform
                    .getDirectoryPath(dialogTitle: "WhatsApp folder");
                _setNewPath('waPath', newPath);
                setState(() => _waPath = newPath ?? _waPath);
              },
            ),
            SettingsTile.switchTile(
              initialValue: _checkHash,
              onToggle: (value) async {
                final prefs = await GetIt.I.getAsync<SharedPreferences>();
                await prefs.setBool('checkHash', value);

                setState(() => _checkHash = value);
              },
              title: const Text('Check file hash'),
              description: const Text('This option will make scan very slow'),
            )
          ],
        ),
      ],
    );
  }

  Future<String?> _showPreferenceDialog({
    required final _InputDialog dialog,
    required final String key,
  }) async {
    final String? newPath = await showDialog(
      context: context,
      builder: (context) => dialog,
    );
    _setNewPath(key, newPath);

    return newPath;
  }

  Future<void> _setNewPath(final String key, final String? path) async {
    if (path != null) {
      final prefs = await GetIt.I.getAsync<SharedPreferences>();
      await prefs.setString(key, path);
    }
  }
}

class _InputDialog extends StatelessWidget {
  _InputDialog(final this.title, {final String? text})
      : pathController = TextEditingController(text: text);

  final String title;
  final TextEditingController pathController;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: pathController,
        autocorrect: false,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(pathController.text),
          child: const Text("Ok"),
        )
      ],
    );
  }
}
