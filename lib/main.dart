import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/clipboard/presentation/screens/main_clipboard_screen.dart';
import 'features/settings/presentation/settings_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ClipboardManagerApp(),
    ),
  );
}

class ClipboardManagerApp extends ConsumerWidget {
  const ClipboardManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(settingsProvider.select((s) => s.themeMode));

    return MaterialApp(
      title: 'Clipper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const MainClipboardScreen(),
    );
  }
}
