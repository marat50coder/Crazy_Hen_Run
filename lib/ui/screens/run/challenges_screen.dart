import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/running_challenge.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  String _format(double value, String unit) {
    if (unit == 'm') {
      if (value < 1000) return '${value.round()} m';
      return '${(value / 1000).toStringAsFixed(1)} km';
    }
    return '${value.round()} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final challenges = RunningChallenge.catalog;
    final done = challenges
        .where((ch) => ch.isDoneFrom(run.challengeValue(ch.metric)))
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('Challenges')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          Insets.sm,
          Insets.md,
          Insets.xxl,
        ),
        children: <Widget>[
          SoftCard(
            padding: const EdgeInsets.all(Insets.md),
            child: Row(
              children: <Widget>[
                const HenFigure(asset: 'assets/achivments_and_strong_chicken.webp', size: 60),
                const SizedBox(width: Insets.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('$done of ${challenges.length} cleared',
                          style: context.text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Chase these to keep the hen sprinting. Progress updates live '
                        'from your runs and steps.',
                        style: context.text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          ...challenges.map((ch) {
            final value = run.challengeValue(ch.metric);
            return Padding(
              padding: const EdgeInsets.only(bottom: Insets.sm),
              child: _ChallengeCard(
                challenge: ch,
                current: value,
                label: _format(value, ch.unit),
                target: _format(ch.target, ch.unit),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.challenge,
    required this.current,
    required this.label,
    required this.target,
  });

  final RunningChallenge challenge;
  final double current;
  final String label;
  final String target;

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progressFrom(current);
    final done = challenge.isDoneFrom(current);

    return SoftCard(
      padding: const EdgeInsets.all(Insets.md),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 56,
            height: 56,
            child: ProgressRing(
              value: progress,
              size: 56,
              stroke: 6,
              color: challenge.color,
              child: done
                  ? Icon(Icons.check_rounded, color: challenge.color, size: 22)
                  : Icon(challenge.icon, color: challenge.color, size: 20),
            ),
          ),
          const SizedBox(width: Insets.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: Text(challenge.title, style: context.text.titleSmall)),
                    Text('$label / $target', style: context.text.labelMedium),
                  ],
                ),
                const SizedBox(height: 2),
                Text(challenge.blurb, style: context.text.bodySmall),
                const SizedBox(height: 8),
                TrackBar(value: progress, height: 6, color: challenge.color),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
