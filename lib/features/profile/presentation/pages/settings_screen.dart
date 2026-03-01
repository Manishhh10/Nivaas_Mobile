import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nivaas/app/theme/theme_mode_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF6518);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Theme',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          _themeOption(
            context: context,
            ref: ref,
            title: 'Light',
            subtitle: 'Always use light theme',
            value: ThemeMode.light,
            groupValue: themeMode,
          ),
          _themeOption(
            context: context,
            ref: ref,
            title: 'Dark',
            subtitle: 'Always use dark theme',
            value: ThemeMode.dark,
            groupValue: themeMode,
          ),
          _themeOption(
            context: context,
            ref: ref,
            title: 'Auto',
            subtitle: 'Use ambient light sensor (bright room = light theme)',
            value: ThemeMode.system,
            groupValue: themeMode,
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required ThemeMode value,
    required ThemeMode groupValue,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: RadioListTile<ThemeMode>(
        value: value,
        groupValue: groupValue,
        activeColor: primaryOrange,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        onChanged: (mode) {
          if (mode != null) {
            ref.read(themeModeProvider.notifier).setThemeMode(mode);
          }
        },
      ),
    );
  }
}
