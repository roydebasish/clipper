import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../clipboard/presentation/providers/clipboard_state.dart';
import '../../domain/settings_state.dart';
import '../settings_provider.dart';

class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
  int _selectedTab = 0;
  final TextEditingController _appController = TextEditingController();

  final List<String> _tabs = [
    'General',
    'Clipboard',
    'Privacy',
    'Shortcuts',
    'About',
  ];

  @override
  void dispose() {
    _appController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: AppTheme.cardBg(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppTheme.border(context), width: 1.0),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, minHeight: 460, maxHeight: 520),
        child: Column(
          children: [
            // macOS Window Header
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.sidebarBg(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: AppTheme.border(context))),
              ),
              child: Row(
                children: [
                  const Text(
                    'Clipper Settings',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Segmented Tabs
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C3038) : const Color(0xFFDFE2E8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: Row(
                      children: List.generate(_tabs.length, (index) {
                        final isSelected = _selectedTab == index;
                        return InkWell(
                          onTap: () => setState(() => _selectedTab = index),
                          borderRadius: BorderRadius.circular(6),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF3F4450) : Colors.white)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 3,
                                        offset: const Offset(0, 1),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              _tabs[index],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected
                                    ? AppTheme.textPrimary(context)
                                    : AppTheme.textSecondary(context),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: AppTheme.textSecondary(context)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildGeneralTab(context, settings, notifier),
                    _buildClipboardTab(context, settings, notifier),
                    _buildPrivacyTab(context, settings, notifier),
                    _buildShortcutsTab(context),
                    _buildAboutTab(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. General Tab (Theme & Window options)
  Widget _buildGeneralTab(BuildContext context, SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      children: [
        const Text(
          'APPEARANCE',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildThemeOption(
              context: context,
              title: 'Light',
              subtitle: 'Clean & Crisp',
              icon: Icons.light_mode,
              mode: ThemeMode.light,
              currentMode: settings.themeMode,
              onTap: () => notifier.setThemeMode(ThemeMode.light),
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              context: context,
              title: 'Dark',
              subtitle: 'Sleek Graphite',
              icon: Icons.dark_mode,
              mode: ThemeMode.dark,
              currentMode: settings.themeMode,
              onTap: () => notifier.setThemeMode(ThemeMode.dark),
            ),
            const SizedBox(width: 12),
            _buildThemeOption(
              context: context,
              title: 'System',
              subtitle: 'Auto Match macOS',
              icon: Icons.computer,
              mode: ThemeMode.system,
              currentMode: settings.themeMode,
              onTap: () => notifier.setThemeMode(ThemeMode.system),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'APPLICATION BEHAVIOR',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: const Text('Keep running in background', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            'Closing the main window leaves Clipper running in the menu bar.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
          ),
          value: settings.runInBackground,
          activeTrackColor: AppTheme.macBlue,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) => notifier.toggleRunInBackground(),
        ),
        SwitchListTile.adaptive(
          title: const Text('Launch at system login', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            'Automatically start Clipper when you log into your Mac.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
          ),
          value: settings.launchAtLogin,
          activeTrackColor: AppTheme.macBlue,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) => notifier.toggleLaunchAtLogin(),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode currentMode,
    required VoidCallback onTap,
  }) {
    final isSelected = currentMode == mode;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.macBlue.withValues(alpha: 0.08) : AppTheme.sidebarBg(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.macBlue : AppTheme.border(context),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 24, color: isSelected ? AppTheme.macBlue : AppTheme.textSecondary(context)),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? AppTheme.macBlue : AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: AppTheme.textSecondary(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDuplicateOption({
    required BuildContext context,
    required String title,
    required String subtitle,
    required DuplicateHandlingOption option,
    required DuplicateHandlingOption currentOption,
    required VoidCallback onTap,
  }) {
    final isSelected = currentOption == option;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.macBlue.withValues(alpha: 0.08) : AppTheme.sidebarBg(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.macBlue : AppTheme.border(context),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? AppTheme.macBlue : AppTheme.textSecondary(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppTheme.macBlue : AppTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Clipboard Tab (Duplicate handling & History rules)
  Widget _buildClipboardTab(BuildContext context, SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      children: [
        const Text(
          'DUPLICATE HANDLING',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 10),
        _buildDuplicateOption(
          context: context,
          title: 'Move existing item to top (Recommended)',
          subtitle: 'Bumps repeated copies to top and increments copy count.',
          option: DuplicateHandlingOption.moveToTop,
          currentOption: settings.duplicateHandling,
          onTap: () => notifier.setDuplicateHandling(DuplicateHandlingOption.moveToTop),
        ),
        _buildDuplicateOption(
          context: context,
          title: 'Keep duplicates',
          subtitle: 'Creates a new separate entry for each copy event.',
          option: DuplicateHandlingOption.keepDuplicates,
          currentOption: settings.duplicateHandling,
          onTap: () => notifier.setDuplicateHandling(DuplicateHandlingOption.keepDuplicates),
        ),
        _buildDuplicateOption(
          context: context,
          title: 'Ignore duplicates',
          subtitle: 'Do not record copies if the item is already present in history.',
          option: DuplicateHandlingOption.ignoreDuplicate,
          currentOption: settings.duplicateHandling,
          onTap: () => notifier.setDuplicateHandling(DuplicateHandlingOption.ignoreDuplicate),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'HISTORY LIMITS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Maximum items kept in history', style: TextStyle(fontSize: 13)),
                Text('Older unpinned items are automatically pruned.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context))),
              ],
            ),
            DropdownButton<int>(
              value: settings.maxHistoryItems,
              dropdownColor: AppTheme.cardBg(context),
              items: const [
                DropdownMenuItem(value: 500, child: Text('500 items')),
                DropdownMenuItem(value: 1000, child: Text('1,000 items')),
                DropdownMenuItem(value: 5000, child: Text('5,000 items')),
                DropdownMenuItem(value: 10000, child: Text('10,000 items')),
              ],
              onChanged: (val) {
                if (val != null) notifier.setMaxHistoryItems(val);
              },
            ),
          ],
        ),
      ],
    );
  }

  // 3. Privacy & Exclusions Tab
  Widget _buildPrivacyTab(BuildContext context, SettingsState settings, SettingsNotifier notifier) {
    return ListView(
      children: [
        const Text(
          'SECURITY & PRIVACY',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 8),
        SwitchListTile.adaptive(
          title: const Text('Detect & flag sensitive data', style: TextStyle(fontSize: 13)),
          subtitle: Text(
            'Automatically highlights private keys, authentication tokens, and passwords.',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
          ),
          value: settings.detectSensitive,
          activeTrackColor: AppTheme.macBlue,
          contentPadding: EdgeInsets.zero,
          onChanged: (_) => notifier.toggleDetectSensitive(),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'EXCLUDED APPLICATIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          'Copies originating from these apps will be completely ignored and not saved.',
          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 34,
                decoration: BoxDecoration(
                  color: AppTheme.sidebarBg(context),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.border(context)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: TextField(
                  controller: _appController,
                  style: const TextStyle(fontSize: 12),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'App name or bundle ID (e.g. 1Password, com.tinyspeck.slackmacgap)',
                    hintStyle: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_appController.text.isNotEmpty) {
                  notifier.addExcludedApp(_appController.text);
                  _appController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.macBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
              child: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: settings.excludedApps.map((app) {
            return Chip(
              backgroundColor: AppTheme.sidebarBg(context),
              side: BorderSide(color: AppTheme.border(context)),
              label: Text(app, style: const TextStyle(fontSize: 11)),
              deleteIcon: const Icon(Icons.close, size: 12),
              onDeleted: () => notifier.removeExcludedApp(app),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 4. Shortcuts Tab
  Widget _buildShortcutsTab(BuildContext context) {
    final shortcuts = [
      {'key': '⌘ + ⇧ + V', 'desc': 'Open Quick Clipboard from anywhere'},
      {'key': '⌘ + K', 'desc': 'Focus and filter Search history'},
      {'key': '⌘ + ,', 'desc': 'Open Settings & Preferences'},
      {'key': 'Enter', 'desc': 'Copy selected clipboard item'},
      {'key': 'Esc', 'desc': 'Clear search filter or close dialogs'},
      {'key': '⌘ + D', 'desc': 'Delete selected clipboard item'},
      {'key': '⌘ + P', 'desc': 'Toggle Pin on current item'},
    ];

    return ListView(
      children: [
        const Text(
          'KEYBOARD SHORTCUTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FixedColumnWidth(140),
            1: FlexColumnWidth(),
          },
          children: shortcuts.map((item) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.sidebarBg(context),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border(context)),
                    ),
                    child: Text(
                      item['key']!,
                      style: const TextStyle(
                        fontFamily: 'SF Mono, Menlo, monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.macBlue,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  child: Text(
                    item['desc']!,
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary(context)),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // 5. About Tab
  Widget _buildAboutTab(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.macBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.content_paste_rounded, size: 36, color: AppTheme.macBlue),
          ),
          const SizedBox(height: 12),
          const Text(
            'Clipper',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0 (Native AppKit + Flutter)',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              'A high-performance, privacy-first clipboard productivity utility for macOS built with continuous background NSPasteboard monitoring, Carbon global hotkeys, and persistent local storage.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
