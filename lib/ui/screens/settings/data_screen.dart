import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../domain/hen_state.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/surfaces.dart';

/// Storage overview plus the destructive actions, kept deliberately plain so
/// nothing here looks like a button you press by accident.
class DataScreen extends StatelessWidget {
  const DataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Data & storage')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          0,
          Insets.md,
          Insets.xxl,
        ),
        children: <Widget>[
          SoftCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.phone_android_rounded, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Stored on this device', style: context.text.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'Crazy Hen Run has no product server. Habits, journal '
                        'entries and photos stay on this device. AppsFlyer only '
                        'receives install and anonymous usage events.',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(title: 'What is stored'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _CountRow(
                  icon: Icons.checklist_rounded,
                  label: 'Active habits',
                  value: '${app.habits.length}',
                ),
                _CountRow(
                  icon: Icons.inventory_2_rounded,
                  label: 'Archived habits',
                  value: '${app.archivedHabits.length}',
                ),
                _CountRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Completed logs',
                  value: '${app.totalCompletions}',
                ),
                _CountRow(
                  icon: Icons.auto_stories_rounded,
                  label: 'Journal entries',
                  value: '${app.journal.length}',
                ),
                _CountRow(
                  icon: Icons.photo_rounded,
                  label: 'Profile photo',
                  value: app.profile.avatarPath.isEmpty ? 'None' : 'Saved',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(title: 'Export'),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Copy a JSON snapshot of everything to the clipboard. Paste it '
                  'into a note or a file to keep your own backup.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: Insets.md),
                OutlinedButton.icon(
                  onPressed: () async {
                    final json = const JsonEncoder.withIndent('  ')
                        .convert(app.exportSnapshot());
                    await Clipboard.setData(ClipboardData(text: json));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Snapshot copied to the clipboard'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 18),
                  label: const Text('Copy backup JSON'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(title: 'Danger zone'),
          SoftCard(
            border: true,
            color: c.danger.withValues(alpha: 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Reset everything',
                  style: context.text.titleSmall?.copyWith(color: c.danger),
                ),
                const SizedBox(height: 4),
                Text(
                  'Deletes every habit, log, journal entry and your profile. '
                  'There is no undo and no backup on our side.',
                  style: context.text.bodyMedium,
                ),
                const SizedBox(height: Insets.md),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.danger,
                    side: BorderSide(color: c.danger.withValues(alpha: 0.5)),
                  ),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset everything?'),
                        content: const Text(
                          'All habits, logs, journal entries and your profile '
                          'will be permanently deleted from this device.',
                        ),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: c.danger,
                              minimumSize: const Size(110, 46),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await app.resetEverything();
                    if (context.mounted) {
                      await context.read<RunTracker>().resetEverything();
                    }
                    if (!context.mounted) return;
                    context.read<RunTracker>().resetRunningData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Everything has been reset')),
                    );
                  },
                  icon: const Icon(Icons.delete_forever_rounded, size: 18),
                  label: const Text('Reset all data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.icon,
    required this.label,
    required this.value,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: 14,
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 19, color: c.textSecondary),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: context.text.bodyLarge)),
              Text(value, style: context.text.titleSmall),
            ],
          ),
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.only(left: 50, right: Insets.md),
            child: Divider(height: 1, color: c.outline),
          ),
      ],
    );
  }
}
