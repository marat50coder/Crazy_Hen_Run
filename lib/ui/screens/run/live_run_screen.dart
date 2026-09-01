import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/formatting.dart';
import '../../../persistence/models/run_goal.dart';
import '../../../persistence/models/run_type.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/go_button.dart';
import '../../widgets/hen.dart';
import 'run_summary_screen.dart';

class LiveRunScreen extends StatefulWidget {
  const LiveRunScreen({
    super.key,
    required this.type,
    this.goal = RunGoal.open,
  });

  final RunType type;
  final RunGoal goal;

  @override
  State<LiveRunScreen> createState() => _LiveRunScreenState();
}

class _LiveRunScreenState extends State<LiveRunScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _runLoop;
  bool _celebratedGoal = false;

  @override
  void initState() {
    super.initState();
    _runLoop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final run = context.read<RunTracker>();
      if (!run.isRunning) run.startRun(widget.type, goal: widget.goal);
    });
  }

  @override
  void dispose() {
    _runLoop.dispose();
    super.dispose();
  }

  void _maybeCelebrate(RunTracker run) {
    if (_celebratedGoal) return;
    if (!run.consumeGoalReachedEvent()) return;
    _celebratedGoal = true;
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Meadow.go,
          content: Text(
            'Goal reached — ${widget.goal.chipLabel}. Keep going or tap flag to finish.',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
  }

  Future<void> _finish() async {
    final run = context.read<RunTracker>();
    final session = await run.finishRun();
    if (!mounted || session == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RunSummaryScreen(runId: session.id)),
    );
  }

  Future<void> _confirmDiscard() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this run?'),
        content: const Text('Your progress for this session will not be saved.'),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: <Widget>[
          GoButton(
            label: 'Keep running',
            icon: Icons.play_arrow_rounded,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          const SizedBox(height: 10),
          GoButton(
            label: 'Discard',
            icon: Icons.flag_rounded,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<RunTracker>().discardRun();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final run = context.watch<RunTracker>();
    final type = widget.type;
    final onColor = Colors.white;
    final goal = widget.goal;
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeCelebrate(run));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                type.color,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.35), type.color),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(Insets.lg),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(type.icon, color: onColor),
                      const SizedBox(width: 8),
                      Text(
                        type.label,
                        style: context.text.titleMedium?.copyWith(color: onColor),
                      ),
                      const Spacer(),
                      if (run.isPaused)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(Corners.pill),
                          ),
                          child: Text('PAUSED',
                              style: context.text.labelSmall?.copyWith(color: onColor)),
                        )
                      else
                        _LiveDot(color: onColor),
                    ],
                  ),
                  const Spacer(),
                  _timerBlock(run, goal, onColor),
                  const SizedBox(height: Insets.lg),
                  _runnerLane(type),
                  const SizedBox(height: Insets.lg),
                  _metrics(run, onColor),
                  const Spacer(),
                  _controls(run),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timerBlock(RunTracker run, RunGoal goal, Color onColor) {
    final elapsed = Text(
      _fmt(run.elapsedSec),
      style: context.text.displayLarge?.copyWith(
        color: onColor,
        fontSize: 68,
        fontWeight: FontWeight.w700,
      ),
    );
    final subtitle = Text(
      'DURATION',
      style: context.text.labelSmall?.copyWith(
        color: onColor.withValues(alpha: 0.8),
        letterSpacing: 2,
      ),
    );
    if (goal.isOpen) {
      return Column(children: <Widget>[elapsed, subtitle]);
    }
    final progress = goal.progress(
      distanceMeters: run.liveDistanceMeters,
      durationSec: run.elapsedSec,
    );
    final reached = progress >= 1.0;
    final goalText = _goalCaption(goal, run);
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          SizedBox.expand(
            child: CustomPaint(
              painter: _GoalRingPainter(
                progress: progress,
                track: onColor.withValues(alpha: 0.22),
                fill: reached ? Meadow.go : onColor,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              elapsed,
              subtitle,
              const SizedBox(height: 4),
              Text(
                goalText,
                style: context.text.labelMedium?.copyWith(
                  color: reached ? Meadow.go : onColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _goalCaption(RunGoal goal, RunTracker run) {
    switch (goal.kind) {
      case RunGoalKind.open:
        return '';
      case RunGoalKind.distance:
        final current = run.liveDistanceMeters;
        return '${current.formatDistanceCompact()} / ${goal.chipLabel}';
      case RunGoalKind.duration:
        final left = math.max(0, goal.value - run.elapsedSec);
        return left == 0
            ? 'Goal ${goal.chipLabel}'
            : '${left.formatClock()} left';
    }
  }

  Widget _runnerLane(RunType type) {
    return SizedBox(
      height: 70,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return AnimatedBuilder(
            animation: _runLoop,
            builder: (context, _) {
              final t = _runLoop.value;
              final x = (w - 58) * (0.12 + 0.76 * t);
              final bob = -6 * math.sin(t * math.pi * 2).abs();
              return Stack(
                children: <Widget>[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 6,
                    child: Container(
                      height: 4,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  Positioned(
                    left: x,
                    bottom: 10 - bob,
                    child: HenFigure(asset: type.henAsset, size: 58, idle: false),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _metrics(RunTracker run, Color onColor) {
    Widget cell(String value, String label) => Expanded(
          child: Column(
            children: <Widget>[
              Text(
                value,
                style: context.text.headlineMedium?.copyWith(color: onColor),
              ),
              Text(
                label,
                style: context.text.labelSmall?.copyWith(
                  color: onColor.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );

    final dist = run.liveDistanceMeters;
    final distText = dist.formatDistanceCompact();
    final distUnit = dist.compactDistanceUnit;
    final paceText = run.livePaceSecPerKm.formatPace();

    return Column(
      children: <Widget>[
        Row(children: <Widget>[cell(distText, distUnit), cell(paceText, 'PACE /KM')]),
        const SizedBox(height: Insets.md),
        Row(children: <Widget>[
          cell('${run.liveSteps}', 'STEPS'),
          cell('${run.liveCalories}', 'KCAL'),
        ]),
      ],
    );
  }

  Widget _controls(RunTracker run) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        _CircleButton(
          icon: Icons.close_rounded,
          background: Colors.white.withValues(alpha: 0.18),
          foreground: Colors.white,
          size: 60,
          onTap: _confirmDiscard,
        ),
        _CircleButton(
          icon: run.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
          background: Colors.white,
          foreground: Meadow.go,
          size: 86,
          onTap: () => run.isPaused ? run.resumeRun() : run.pauseRun(),
        ),
        _CircleButton(
          icon: Icons.flag_rounded,
          background: Colors.white.withValues(alpha: 0.18),
          foreground: Colors.white,
          size: 60,
          onTap: _finish,
        ),
      ],
    );
  }

  static String _fmt(int sec) => sec.formatClock();
}

class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color});
  final Color color;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        FadeTransition(
          opacity: _c,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
        const SizedBox(width: 6),
        Text('LIVE',
            style: context.text.labelSmall?.copyWith(color: widget.color, letterSpacing: 2)),
      ],
    );
  }
}

class _GoalRingPainter extends CustomPainter {
  _GoalRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    final rect = Rect.fromCircle(center: centre, radius: radius);
    final basePaint = Paint()
      ..color = track
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(centre, radius, basePaint);
    if (progress <= 0) return;
    final arcPaint = Paint()
      ..color = fill
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _GoalRingPainter old) {
    return old.progress != progress || old.fill != fill || old.track != track;
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.size,
    required this.onTap,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, color: foreground, size: size * 0.42),
      ),
    );
  }
}
