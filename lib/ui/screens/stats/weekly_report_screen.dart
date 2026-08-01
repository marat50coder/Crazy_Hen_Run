import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/day_key.dart';
import '../../../state/app_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

/// A printed-report style summary: one hero verdict, then a week timeline and
/// a this-week vs last-week comparison.
class WeeklyReportScreen extends StatefulWidget {
  const WeeklyReportScreen({super.key});

  @override
  State<WeeklyReportScreen> createState() => _WeeklyReportScreenState();
}

class _WeeklyReportScreenState extends State<WeeklyReportScreen> {
  int _weekOffset = 0;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = context.palette;

    final anchor = DayKey.today().subtract(Duration(days: 7 * _weekOffset));
    final week = DayKey.weekOf(anchor, firstWeekday: app.firstWeekday);
    final previous = DayKey.weekOf(
      anchor.subtract(const Duration(days: 7)),
      firstWeekday: app.firstWeekday,
    );

    final summaries = app.summariesFor(week);
    final prevSummaries = app.summariesFor(previous);

    final completed = summaries.fold<int>(0, (a, s) => a + s.completed);
    final scheduled = summaries.fold<int>(0, (a, s) => a + s.scheduled);
    final prevCompleted = prevSummaries.fold<int>(0, (a, s) => a + s.completed);
    final delta = completed - prevCompleted;
    final ratio = scheduled == 0 ? 0.0 : completed / scheduled;
    final perfect = summaries.where((s) => s.isPerfect).length;

    final verdict = switch (ratio) {
      >= 0.95 => ('Flawless week', 'Nothing slipped. That is rare air.'),
      >= 0.75 => ('Strong week', 'You showed up when it counted.'),
      >= 0.5 => ('Mixed week', 'Half the track is still a lot of track.'),
      > 0 => ('Slow week', 'Pick one habit and protect it next week.'),
      _ => ('Empty week', 'Nothing logged. Start again on Monday.'),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly report'),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() => _weekOffset++),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          IconButton(
            onPressed: _weekOffset == 0
                ? null
                : () => setState(() => _weekOffset--),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(
            '${DayKey.medium(week.first)} — ${DayKey.medium(week.last)}',
            style: context.text.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(c.accent.withValues(alpha: 0.16), c.surface),
                c.surface,
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(verdict.$1, style: context.text.displaySmall),
                      const SizedBox(height: 6),
                      Text(verdict.$2, style: context.text.bodyMedium),
                    ],
                  ),
                ),
                HenFigure(
                  asset: ratio >= 0.75
                      ? AppAssets.henHappy
                      : (ratio > 0 ? AppAssets.henCoach : AppAssets.henCurious),
                  size: 92,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _ReportStat(
                  label: 'Closed',
                  value: '$completed',
                  hint: 'of $scheduled scheduled',
                  tone: c.accent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportStat(
                  label: 'Perfect days',
                  value: '$perfect',
                  hint: 'out of 7',
                  tone: Brand.corn,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ReportStat(
                  label: 'vs last week',
                  value: delta >= 0 ? '+$delta' : '$delta',
                  hint: delta >= 0 ? 'ahead' : 'behind',
                  tone: delta >= 0 ? c.positive : c.danger,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'Day by day'),
          SoftCard(
            child: Column(
              children: List<Widget>.generate(week.length, (i) {
                final day = week[i];
                final s = summaries[i];
                final future = day.isAfter(DayKey.today());
                return Padding(
                  padding: EdgeInsets.only(bottom: i == week.length - 1 ? 0 : 14),
                  child: Row(
                    children: <Widget>[
                      SizedBox(
                        width: 44,
                        child: Text(
                          DayKey.weekdayShort(day.weekday),
                          style: context.text.labelMedium?.copyWith(
                            color: future ? c.textSecondary : c.textPrimary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TrackBar(
                          value: future ? 0 : s.ratio,
                          height: 8,
                          color: s.isPerfect ? c.positive : c.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 44,
                        child: Text(
                          future ? '—' : '${s.completed}/${s.scheduled}',
                          textAlign: TextAlign.right,
                          style: context.text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'What the hen noticed'),
          SoftCard(
            color: c.accentSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.campaign_rounded, color: c.accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _insight(summaries, delta, perfect),
                    style: context.text.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _insight(List<DaySummary> summaries, int delta, int perfect) {
    final withData = summaries.where((s) => s.scheduled > 0).toList();
    if (withData.isEmpty) {
      return 'Nothing was scheduled this week. Add a habit and the report gets interesting.';
    }
    withData.sort((a, b) => b.ratio.compareTo(a.ratio));
    final best = withData.first;
    final worst = withData.last;

    if (perfect >= 5) {
      return 'Five or more perfect days in one week. Whatever your setup is right now, do not change it.';
    }
    if (delta > 0) {
      return 'You closed $delta more habits than last week. ${DayKey.weekdayShort(best.day.weekday)} was your strongest day.';
    }
    if (worst.ratio < 0.4) {
      return '${DayKey.weekdayShort(worst.day.weekday)} keeps slipping. Either move those habits or make them smaller.';
    }
    return 'Steady week. ${DayKey.weekdayShort(best.day.weekday)} carried the most weight.';
  }
}

class _ReportStat extends StatelessWidget {
  const _ReportStat({
    required this.label,
    required this.value,
    required this.hint,
    required this.tone,
  });

  final String label;
  final String value;
  final String hint;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.headlineSmall?.copyWith(color: tone),
          ),
          const SizedBox(height: 2),
          Text(label, style: context.text.labelSmall),
          Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
