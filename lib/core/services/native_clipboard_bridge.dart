import 'dart:async';
import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class NativeClipboardBridge {
  static final NativeClipboardBridge instance = NativeClipboardBridge._internal();

  NativeClipboardBridge._internal() {
    _initChannels();
  }

  final MethodChannel _methodChannel = const MethodChannel(AppConstants.methodChannelName);
  final EventChannel _eventChannel = const EventChannel(AppConstants.eventChannelName);

  Stream<Map<String, dynamic>>? _clipboardStream;
  Function()? onClearHistoryRequested;
  Function()? onGlobalShortcutTriggered;
  Function(Map<String, dynamic> item)? onItemCopiedFromMenuBar;
  Function(String id)? onItemDeletedFromMenuBar;

  void _initChannels() {
    _methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'onClearHistoryRequested':
          onClearHistoryRequested?.call();
          break;
        case 'onGlobalShortcutTriggered':
          onGlobalShortcutTriggered?.call();
          break;
        case 'onItemCopiedFromMenuBar':
          if (call.arguments is Map) {
            onItemCopiedFromMenuBar?.call(Map<String, dynamic>.from(call.arguments as Map));
          }
          break;
        case 'onItemDeletedFromMenuBar':
          if (call.arguments is String) {
            onItemDeletedFromMenuBar?.call(call.arguments as String);
          }
          break;
      }
    });
  }

  Stream<Map<String, dynamic>> get clipboardStream {
    _clipboardStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((event) => Map<String, dynamic>.from(event as Map));
    return _clipboardStream!;
  }

  Future<bool> startMonitoring() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('startMonitoring');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> stopMonitoring() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('stopMonitoring');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> pauseMonitoring({double? seconds}) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('pauseMonitoring', {'seconds': seconds});
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> resumeMonitoring() async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('resumeMonitoring');
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> writeClipboard(String content, {String type = 'TEXT', String? filePath}) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('writeClipboard', {
        'content': content,
        'type': type,
        'filePath': filePath,
      });
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> readClipboard() async {
    try {
      final res = await _methodChannel.invokeMethod<Map>('readClipboard');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, String>?> getFrontmostApplication() async {
    try {
      final res = await _methodChannel.invokeMethod<Map>('getFrontmostApplication');
      if (res != null) {
        return res.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> setExcludedApplications(List<String> bundleIds) async {
    try {
      final res = await _methodChannel.invokeMethod<bool>('setExcludedApplications', bundleIds);
      return res ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> showMainWindow() async {
    try {
      await _methodChannel.invokeMethod('showMainWindow');
    } catch (_) {}
  }

  Future<void> hideMainWindow() async {
    try {
      await _methodChannel.invokeMethod('hideMainWindow');
    } catch (_) {}
  }

  Future<void> toggleMainWindow() async {
    try {
      await _methodChannel.invokeMethod('toggleMainWindow');
    } catch (_) {}
  }

  Future<void> updateMenuBarItems(List<Map<String, dynamic>> items) async {
    try {
      await _methodChannel.invokeMethod('updateMenuBarItems', items);
    } catch (_) {}
  }
}
