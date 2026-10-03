import 'package:flutter/material.dart';
import '../../clipboard/presentation/providers/clipboard_state.dart';

class SettingsState {
  final ThemeMode themeMode;
  final bool launchAtLogin;
  final bool startMinimized;
  final bool runInBackground;
  final DuplicateHandlingOption duplicateHandling;
  final int maxHistoryItems;
  final int autoDeleteDays; // 0 = never, 7, 30, 90, 365
  final bool detectSensitive;
  final List<String> excludedApps;
  final bool soundEffects;

  const SettingsState({
    this.themeMode = ThemeMode.light, // Default to light theme per user request
    this.launchAtLogin = false,
    this.startMinimized = false,
    this.runInBackground = true,
    this.duplicateHandling = DuplicateHandlingOption.moveToTop,
    this.maxHistoryItems = 1000,
    this.autoDeleteDays = 0,
    this.detectSensitive = true,
    this.excludedApps = const ['1Password', 'Bitwarden', 'KeePassXC'],
    this.soundEffects = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? launchAtLogin,
    bool? startMinimized,
    bool? runInBackground,
    DuplicateHandlingOption? duplicateHandling,
    int? maxHistoryItems,
    int? autoDeleteDays,
    bool? detectSensitive,
    List<String>? excludedApps,
    bool? soundEffects,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      launchAtLogin: launchAtLogin ?? this.launchAtLogin,
      startMinimized: startMinimized ?? this.startMinimized,
      runInBackground: runInBackground ?? this.runInBackground,
      duplicateHandling: duplicateHandling ?? this.duplicateHandling,
      maxHistoryItems: maxHistoryItems ?? this.maxHistoryItems,
      autoDeleteDays: autoDeleteDays ?? this.autoDeleteDays,
      detectSensitive: detectSensitive ?? this.detectSensitive,
      excludedApps: excludedApps ?? this.excludedApps,
      soundEffects: soundEffects ?? this.soundEffects,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'launchAtLogin': launchAtLogin,
      'startMinimized': startMinimized,
      'runInBackground': runInBackground,
      'duplicateHandling': duplicateHandling.name,
      'maxHistoryItems': maxHistoryItems,
      'autoDeleteDays': autoDeleteDays,
      'detectSensitive': detectSensitive,
      'excludedApps': excludedApps,
      'soundEffects': soundEffects,
    };
  }

  factory SettingsState.fromMap(Map<String, dynamic> map) {
    ThemeMode mode = ThemeMode.light;
    if (map['themeMode'] == 'dark') mode = ThemeMode.dark;
    if (map['themeMode'] == 'system') mode = ThemeMode.system;

    DuplicateHandlingOption dup = DuplicateHandlingOption.moveToTop;
    if (map['duplicateHandling'] == 'keepDuplicates') dup = DuplicateHandlingOption.keepDuplicates;
    if (map['duplicateHandling'] == 'ignoreDuplicate') dup = DuplicateHandlingOption.ignoreDuplicate;

    return SettingsState(
      themeMode: mode,
      launchAtLogin: map['launchAtLogin'] == true,
      startMinimized: map['startMinimized'] == true,
      runInBackground: map['runInBackground'] ?? true,
      duplicateHandling: dup,
      maxHistoryItems: (map['maxHistoryItems'] as num?)?.toInt() ?? 1000,
      autoDeleteDays: (map['autoDeleteDays'] as num?)?.toInt() ?? 0,
      detectSensitive: map['detectSensitive'] ?? true,
      excludedApps: (map['excludedApps'] as List?)?.map((e) => e.toString()).toList() ?? const ['1Password', 'Bitwarden'],
      soundEffects: map['soundEffects'] ?? true,
    );
  }
}
