import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/app_meta.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../domain/hen_state.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/avatar.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';
import '../coop/achievements_screen.dart';
import '../habit/archive_screen.dart';
import '../journal/journal_screen.dart';
import '../run/run_history_screen.dart';
import '../settings/about_screen.dart';
import '../settings/settings_screen.dart';
import '../web/web_doc_screen.dart';
import 'edit_profile_screen.dart';

/// Identity screen: a centred hero, a stat band, then a compact link list.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final run = context.watch<RunTracker>();
    final c = context.palette;
    final days = DateTime.now().difference(app.profile.joinedAt).inDays + 1;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            Insets.md,
            Insets.sm,
            Insets.md,
            140,
          ),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  ),
                  icon: Icon(Icons.settings_rounded, color: c.textSecondary),
                ),
              ],
            ),
            Center(
              child: Column(
                children: <Widget>[
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      ProfileAvatar(
                        profile: app.profile,
                        size: 128,
                        ringWidth: 3.5,
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: c.accent,
                            shape: BoxShape.circle,
                            border: Border.all(color: c.canvas, width: 3),
                          ),
                          child: Icon(
                            Icons.photo_camera_rounded,
                            size: 16,
                            color: c.accent.computeLuminance() > 0.55
                                ? c.textPrimary
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Insets.md),
                  Text(app.profile.name, style: context.text.displaySmall),
                  const SizedBox(height: 2),
                  Text(app.profile.tagline, style: context.text.bodyMedium),
                  const SizedBox(height: Insets.sm),
                  Wrap(
                    spacing: 8,
                    children: <Widget>[
                      TagChip(
                        label: run.rank.title,
                        icon: Icons.military_tech_rounded,
                        color: Meadow.corn,
                      ),
                      TagChip(
                        label: '${run.totalRuns} runs',
                        icon: Icons.directions_run_rounded,
                        color: c.accent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),
            SoftCard(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: <Widget>[
                  _Stat(value: run.distanceLabelOf(run.lifetimeMeters), label: 'Distance'),
                  _Divider(),
                  _Stat(value: '${run.totalRuns}', label: 'Runs'),
                  _Divider(),
                  _Stat(value: '${run.dayStreak}', label: 'Streak'),
                  _Divider(),
                  _Stat(value: '$days', label: 'Days here'),
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
            SoftCard(
              padding: const EdgeInsets.all(Insets.md),
              child: Row(
                children: <Widget>[
                  HenFigure(asset: run.rank.asset, size: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Next rank',
                          style: context.text.labelSmall,
                        ),
                        Text(
                          run.rank.next?.title ?? 'Max rank reached',
                          style: context.text.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        TrackBar(value: run.rankProgress, height: 7),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Insets.lg),
            SectionHeader(title: 'Your stuff'),
            _LinkGroup(
              items: <_LinkItem>[
                _LinkItem(
                  icon: Icons.edit_rounded,
                  label: 'Edit profile',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.directions_run_rounded,
                  label: 'Run history',
                  trailing: '${run.totalRuns}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const RunHistoryScreen(),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Achievements',
                  trailing: '${app.unlockedCount}/${app.achievements.length}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'Journal',
                  trailing: '${app.journal.length}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const JournalScreen(),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.inventory_2_rounded,
                  label: 'Archived habits',
                  trailing: '${app.archivedHabits.length}',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ArchiveScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            SectionHeader(title: 'Support & legal'),
            _LinkGroup(
              items: <_LinkItem>[
                _LinkItem(
                  icon: Icons.support_agent_rounded,
                  label: 'Support',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WebDocScreen(
                        title: 'Support',
                        url: AppMeta.supportUrl,
                      ),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.privacy_tip_rounded,
                  label: 'Privacy Policy',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WebDocScreen(
                        title: 'Privacy Policy',
                        url: AppMeta.privacyPolicyUrl,
                      ),
                    ),
                  ),
                ),
                _LinkItem(
                  icon: Icons.info_rounded,
                  label: 'About the app',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            Center(
              child: Text(
                'Member since ${DayKey.medium(app.profile.joinedAt)}',
                style: context.text.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: context.palette.outline,
    );
  }
}

class _LinkItem {
  const _LinkItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
}

class _LinkGroup extends StatelessWidget {
  const _LinkGroup({required this.items});

  final List<_LinkItem> items;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: List<Widget>.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: <Widget>[
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(i == 0 ? Corners.lg : 0),
                  bottom: Radius.circular(
                    i == items.length - 1 ? Corners.lg : 0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Insets.md,
                    vertical: 15,
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(item.icon, size: 20, color: c.textSecondary),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(item.label, style: context.text.titleSmall),
                      ),
                      if (item.trailing != null) ...<Widget>[
                        Text(item.trailing!, style: context.text.bodySmall),
                        const SizedBox(width: 6),
                      ],
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: c.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              if (i != items.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 50),
                  child: Divider(height: 1, color: c.outline),
                ),
            ],
          );
        }),
      ),
    );
  }
}
