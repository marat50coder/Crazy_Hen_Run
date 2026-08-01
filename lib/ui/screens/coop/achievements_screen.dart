import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/achievement.dart';
import '../../../state/app_state.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

/// Badge wall grouped by theme, with a progress summary pinned to the top.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = context.palette;
    final all = app.achievements;
    final unlocked = all.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: <Widget>[
                ProgressRing(
                  value: all.isEmpty ? 0 : unlocked / all.length,
                  size: 78,
                  stroke: 9,
                  child: Text('$unlocked', style: context.text.headlineSmall),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$unlocked of ${all.length} unlocked',
                        style: context.text.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        unlocked == all.length
                            ? 'Every badge collected. Genuinely impressive.'
                            : 'Badges unlock automatically as your numbers grow.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...AchievementGroup.values.map((group) {
            final items =
                all.where((a) => a.achievement.group == group).toList();
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeader(
                  title: group.label,
                  subtitle:
                      '${items.where((i) => i.unlocked).length}/${items.length} unlocked',
                ),
                AnimationLimiter(
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        AnimationConfiguration.staggeredGrid(
                      position: i,
                      columnCount: 2,
                      duration: const Duration(milliseconds: 340),
                      child: ScaleAnimation(
                        scale: 0.94,
                        child: FadeInAnimation(
                          child: _BadgeCard(progress: items[i]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            );
          }),
          Center(
            child: Text(
              'Keep running — new badges appear as you go.',
              style: context.text.bodySmall?.copyWith(color: c.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.progress});

  final AchievementProgress progress;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final a = progress.achievement;
    final unlocked = progress.unlocked;

    return SoftCard(
      padding: const EdgeInsets.all(14),
      color: unlocked ? a.color.withValues(alpha: 0.10) : c.surface,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: a.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(a.icon, color: a.color),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(a.title, style: context.text.headlineSmall),
              const SizedBox(height: 4),
              Text(a.description, style: context.text.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              TrackBar(value: progress.ratio, color: a.color),
              const SizedBox(height: 8),
              Text(
                unlocked
                    ? 'Unlocked'
                    : '${progress.current} / ${a.threshold}',
                style: context.text.labelMedium,
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: unlocked
                      ? a.color.withValues(alpha: 0.18)
                      : c.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(
                  a.icon,
                  size: 21,
                  color: unlocked ? a.color : c.textSecondary,
                ),
              ),
              if (!unlocked)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.outline),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 10,
                      color: c.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            a.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.text.titleSmall?.copyWith(
              color: unlocked ? c.textPrimary : c.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          TrackBar(
            value: progress.ratio,
            height: 5,
            color: unlocked ? a.color : c.outlineStrong,
          ),
          const SizedBox(height: 6),
          Text(
            unlocked ? 'Unlocked' : '${progress.current}/${a.threshold}',
            style: context.text.labelSmall,
          ),
        ],
      ),
    );
  }
}
