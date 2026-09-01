import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/constants/app_meta.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../domain/hen_state.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';
import '../habit/archive_screen.dart';
import '../habit/habit_library_screen.dart';
import '../run/challenges_screen.dart';
import '../run/interval_plans_screen.dart';
import '../run/steps_screen.dart';
import '../sprint/sprint_screen.dart';
import '../web/web_doc_screen.dart';
import 'about_screen.dart';
import 'appearance_screen.dart';
import 'data_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static String _clock(int minuteOfDay) {
    final hour = minuteOfDay ~/ 60;
    final minute = minuteOfDay % 60;
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _pickRunChime(BuildContext context, HenState app) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: app.runChimeMinute ~/ 60,
        minute: app.runChimeMinute % 60,
      ),
    );
    if (picked == null) return;
    await app.setRunChimeMinute(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final run = context.watch<RunTracker>();
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
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
            padding: const EdgeInsets.all(Insets.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(c.accent.withValues(alpha: 0.14), c.surface),
                c.surface,
              ],
            ),
            child: Row(
              children: <Widget>[
                const HenFigure(asset: Artwork.henCoach, size: 62),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(AppMeta.appName, style: context.text.titleMedium),
                      Text(
                        'Version ${AppMeta.version} · works fully offline',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          _Group(
            title: 'Look and feel',
            children: <Widget>[
              _NavRow(
                icon: Icons.palette_rounded,
                title: 'Appearance',
                subtitle: switch (app.themeMode) {
                  ThemeMode.light => 'Light theme',
                  ThemeMode.dark => 'Dark theme',
                  ThemeMode.system => 'Follows the system',
                },
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: app.accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.outline),
                  ),
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AppearanceScreen(),
                  ),
                ),
              ),
              _SwitchRow(
                icon: Icons.vibration_rounded,
                title: 'Haptic feedback',
                subtitle: 'A small tap when you close a habit',
                value: app.haptics,
                onChanged: app.setHaptics,
              ),
              _SwitchRow(
                icon: Icons.celebration_rounded,
                title: 'Celebrations',
                subtitle: 'Confetti when an achievement unlocks',
                value: app.celebrate,
                onChanged: app.setCelebrate,
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          _Group(
            title: 'Running',
            children: <Widget>[
              _NavRow(
                icon: Icons.directions_walk_rounded,
                title: 'Steps & goals',
                subtitle: run.sensorAvailable
                    ? '${run.todaySteps} today · goal ${run.stepGoal}'
                    : run.sensorGranted
                        ? 'Waiting for the step sensor'
                        : 'Step counting is off',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const StepsScreen()),
                ),
              ),
              if (!run.sensorGranted)
                _NavRow(
                  icon: Icons.sensors_rounded,
                  title: 'Enable step counting',
                  subtitle: 'Uses the phone motion sensor — no location',
                  onTap: run.requestSensor,
                ),
              _NavRow(
                icon: Icons.speed_rounded,
                title: 'Interval workouts',
                subtitle: 'Build and run guided intervals',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const IntervalPlansScreen()),
                ),
              ),
              _NavRow(
                icon: Icons.emoji_events_rounded,
                title: 'Challenges',
                subtitle: 'Distance, streak and step goals',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ChallengesScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          _Group(
            title: 'Reminders',
            children: <Widget>[
              _SwitchRow(
                icon: Icons.notifications_active_rounded,
                title: 'Local reminders',
                subtitle: app.chimesOn
                    ? 'Habits with a planned time, plus a daily run nudge'
                    : 'Off — nothing leaves this phone',
                value: app.chimesOn,
                onChanged: app.setChimesOn,
              ),
              _NavRow(
                icon: Icons.directions_run_rounded,
                title: 'Run reminder',
                subtitle: app.chimesOn
                    ? 'Daily at ${_clock(app.runChimeMinute)}'
                    : 'Turn reminders on to pick a time',
                onTap: app.chimesOn
                    ? () => _pickRunChime(context, app)
                    : () {},
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          _Group(
            title: 'Tracking',
            children: <Widget>[
              _SwitchRow(
                icon: Icons.calendar_view_week_rounded,
                title: 'Week starts on Monday',
                subtitle: app.mondayFirst
                    ? 'Monday to Sunday'
                    : 'Sunday to Saturday',
                value: app.mondayFirst,
                onChanged: app.setMondayFirst,
              ),
              _SwitchRow(
                icon: Icons.visibility_off_rounded,
                title: 'Hide completed habits',
                subtitle: 'Keep the Today list focused on what is left',
                value: app.hideCompleted,
                onChanged: app.setHideCompleted,
              ),
              _NavRow(
                icon: Icons.flag_rounded,
                title: 'Weekly sprint',
                subtitle: 'Target: ${app.weeklySprintTarget} habits per week',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const SprintScreen()),
                ),
              ),
              _NavRow(
                icon: Icons.auto_awesome_rounded,
                title: 'Habit ideas',
                subtitle: 'Ready made templates to start from',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HabitLibraryScreen(),
                  ),
                ),
              ),
              _NavRow(
                icon: Icons.inventory_2_rounded,
                title: 'Archived habits',
                subtitle: '${app.archivedHabits.length} in the archive',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ArchiveScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          _Group(
            title: 'Data',
            children: <Widget>[
              _NavRow(
                icon: Icons.storage_rounded,
                title: 'Data & storage',
                subtitle: 'Everything is kept on this device',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const DataScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.md),
          _Group(
            title: 'Support & legal',
            children: <Widget>[
              _NavRow(
                icon: Icons.support_agent_rounded,
                title: 'Support',
                subtitle: 'Ask a question or report a bug',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WebDocScreen(
                      title: 'Support',
                      url: AppMeta.supportUrl,
                    ),
                  ),
                ),
              ),
              _NavRow(
                icon: Icons.privacy_tip_rounded,
                title: 'Privacy Policy',
                subtitle: 'How your data is handled',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WebDocScreen(
                      title: 'Privacy Policy',
                      url: AppMeta.privacyPolicyUrl,
                    ),
                  ),
                ),
              ),
              _NavRow(
                icon: Icons.info_rounded,
                title: 'About',
                subtitle: 'Version, credits and the idea behind it',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: context.text.labelSmall?.copyWith(letterSpacing: 1.2),
          ),
        ),
        SoftCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (var i = 0; i < children.length; i++) ...<Widget>[
                children[i],
                if (i != children.length - 1)
                  Padding(
                    padding: const EdgeInsets.only(left: 54),
                    child: Divider(height: 1, color: c.outline),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: 14,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.bodySmall),
                ],
              ),
            ),
            if (trailing != null) ...<Widget>[
              trailing!,
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: c.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Insets.md,
          vertical: 8,
        ),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 20, color: c.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: context.text.titleSmall),
                  if (subtitle != null)
                    Text(subtitle!, style: context.text.bodySmall),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
