import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/services/native_clipboard_bridge.dart';
import '../../clipboard/presentation/providers/clipboard_state.dart';
import '../domain/settings_state.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<SettingsState> {
  final NativeClipboardBridge _bridge = NativeClipboardBridge.instance;
  File? _settingsFile;

  @override
  SettingsState build() {
    Future.microtask(() => _loadSettings());
    return const SettingsState();
  }

  Future<File> _getFile() async {
    if (_settingsFile != null) return _settingsFile!;
    final dir = await getApplicationSupportDirectory();
    final dataDir = Directory(p.join(dir.path, 'database'));
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    _settingsFile = File(p.join(dataDir.path, 'settings.json'));
    return _settingsFile!;
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isNotEmpty) {
          final map = jsonDecode(content) as Map<String, dynamic>;
          state = SettingsState.fromMap(map);
          _bridge.setExcludedApplications(state.excludedApps);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveSettings(SettingsState newState) async {
    state = newState;
    try {
      final file = await _getFile();
      await file.writeAsString(jsonEncode(newState.toMap()));
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    _saveSettings(state.copyWith(themeMode: mode));
  }

  void setDuplicateHandling(DuplicateHandlingOption option) {
    _saveSettings(state.copyWith(duplicateHandling: option));
  }

  void setMaxHistoryItems(int count) {
    _saveSettings(state.copyWith(maxHistoryItems: count));
  }

  void setAutoDeleteDays(int days) {
    _saveSettings(state.copyWith(autoDeleteDays: days));
  }

  void toggleDetectSensitive() {
    _saveSettings(state.copyWith(detectSensitive: !state.detectSensitive));
  }

  void toggleRunInBackground() {
    _saveSettings(state.copyWith(runInBackground: !state.runInBackground));
  }

  void toggleLaunchAtLogin() {
    _saveSettings(state.copyWith(launchAtLogin: !state.launchAtLogin));
  }

  void toggleStartMinimized() {
    _saveSettings(state.copyWith(startMinimized: !state.startMinimized));
  }

  void addExcludedApp(String appName) {
    final trimmed = appName.trim();
    if (trimmed.isEmpty || state.excludedApps.contains(trimmed)) return;
    final updated = List<String>.from(state.excludedApps)..add(trimmed);
    _saveSettings(state.copyWith(excludedApps: updated));
    _bridge.setExcludedApplications(updated);
  }

  void removeExcludedApp(String appName) {
    final updated = List<String>.from(state.excludedApps)..remove(appName);
    _saveSettings(state.copyWith(excludedApps: updated));
    _bridge.setExcludedApplications(updated);
  }
}
