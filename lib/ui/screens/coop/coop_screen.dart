import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/coach_lines.dart';
import '../../../persistence/models/hen_rank.dart';
import '../../../domain/hen_state.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';
import 'achievements_screen.dart';

/// The character screen. Built as a vertical road of ranks so progression
/// reads top to bottom instead of as another grid of cards.
class CoopScreen extends StatelessWidget {
  const CoopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final run = context.watch<RunTracker>();
    final c = context.palette;
    final rank = run.rank;
    final next = rank.next;
    final totalMetres = run.lifetimeMeters.round();

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: c.canvas,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 15),
              title: Text('The Coop', style: context.text.titleMedium),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.asset(
                    Artwork.background,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.black.withValues(alpha: 0.05),
                          c.canvas.withValues(alpha: 0.35),
                          c.canvas,
                        ],
                        stops: const <double>[0, 0.55, 1],
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 0.15),
                    child: HenFigure(asset: rank.asset, size: 190),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              Insets.md,
              Insets.sm,
              Insets.md,
              140,
            ),
            sliver: SliverList.list(
              children: <Widget>[
                SoftCard(
                  padding: const EdgeInsets.all(Insets.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text('Current rank', style: context.text.labelSmall),
                                Text(rank.title, style: context.text.displaySmall),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text('${run.totalRuns} runs', style: context.text.labelSmall),
                              Text(run.distanceLabelOf(run.lifetimeMeters),
                                  style: context.text.headlineSmall),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(rank.blurb, style: context.text.bodyMedium),
                      const SizedBox(height: Insets.md),
                      TrackBar(value: run.rankProgress, height: 10),
                      const SizedBox(height: 8),
                      Text(
                        next == null
                            ? 'Top rank reached. Now it is just about keeping it.'
                            : '${_metres(next.requiredMetres - totalMetres)} to ${next.title}',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms).moveY(begin: 12, end: 0),
                const SizedBox(height: Insets.md),
                SoftCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AchievementsScreen(),
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      const HenBadge(
                        asset: Artwork.henLegend,
                        size: 54,
                        tint: Meadow.corn,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Achievements', style: context.text.titleMedium),
                            Text(
                              '${app.unlockedCount} of ${app.achievements.length} unlocked',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: c.textSecondary),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                SectionHeader(
                  title: 'The road ahead',
                  subtitle: 'Distance is earned by running and daily steps',
                ),
                ...HenRank.values.map(
                  (r) => _RankRow(
                    rank: r,
                    reached: totalMetres >= r.requiredMetres,
                    current: r == rank,
                    isLast: r == HenRank.values.last,
                  ),
                ),
                const SizedBox(height: Insets.lg),
                SoftCard(
                  color: Meadow.lavender.withValues(alpha: 0.10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const HenFigure(asset: Artwork.henCoach, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Tip of the day', style: context.text.titleSmall),
                            const SizedBox(height: 4),
                            Text(
                              Coach.tipOfDay(DateTime.now().day * 3 + DateTime.now().month),
                              style: context.text.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _metres(int value) {
    final safe = value < 0 ? 0 : value;
    if (safe < 1000) return '$safe m';
    return '${(safe / 1000).toStringAsFixed(1)} km';
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.reached,
    required this.current,
    required this.isLast,
  });

  final HenRank rank;
  final bool reached;
  final bool current;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 32,
            child: Column(
              children: <Widget>[
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached ? c.accent : c.surface,
                    border: Border.all(
                      color: reached ? c.accent : c.outlineStrong,
                      width: 2.5,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: reached ? c.accent.withValues(alpha: 0.5) : c.outline,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: SoftCard(
                elevated: current,
                color: current ? c.accentSoft : c.surface,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: <Widget>[
                    Opacity(
                      opacity: reached ? 1 : 0.42,
                      child: HenFigure(
                        asset: rank.asset,
                        size: 52,
                        idle: current,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(rank.title, style: context.text.titleSmall),
                              const SizedBox(width: 8),
                              if (current)
                                TagChip(label: 'You', dense: true, color: c.accent),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rank.requiredMetres == 0
                                ? 'Starting line'
                                : '${(rank.requiredMetres / 1000).toStringAsFixed(0)} km of distance',
                            style: context.text.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (reached)
                      Icon(Icons.check_circle_rounded, size: 20, color: c.accent)
                    else
                      Icon(Icons.lock_rounded, size: 18, color: c.textSecondary),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
