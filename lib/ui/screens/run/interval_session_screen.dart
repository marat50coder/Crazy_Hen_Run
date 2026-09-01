import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/interval_plan.dart';
import '../../../persistence/models/run_type.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import 'run_summary_screen.dart';

class IntervalSessionScreen extends StatefulWidget {
  const IntervalSessionScreen({super.key, required this.plan});

  final IntervalPlan plan;

  @override
  State<IntervalSessionScreen> createState() => _IntervalSessionScreenState();
}

class _IntervalSessionScreenState extends State<IntervalSessionScreen> {
  late final List<IntervalSegment> _timeline = widget.plan.timeline;
  Timer? _timer;
  int _index = 0;
  int _phaseElapsed = 0;
  bool _paused = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final run = context.read<RunTracker>();
      if (!run.isRunning) run.startRun(RunType.interval);
      _start();
    });
  }

  void _start() {
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() {
        _phaseElapsed++;
        if (_phaseElapsed >= _timeline[_index].seconds) {
          if (_index >= _timeline.length - 1) {
            _finish();
          } else {
            _index++;
            _phaseElapsed = 0;
            HapticFeedback.mediumImpact();
          }
        }
      });
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    final run = context.read<RunTracker>();
    final session = await run.finishRun();
    if (!mounted) return;
    if (session == null) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => RunSummaryScreen(runId: session.id)),
    );
  }

  Future<void> _stopEarly() async {
    _timer?.cancel();
    await _finish();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final seg = _timeline[_index];
    final color = Color.lerp(Meadow.sky, Meadow.comb, seg.intensity)!;
    final remaining = seg.seconds - _phaseElapsed;
    final phaseProgress = seg.seconds <= 0 ? 0.0 : _phaseElapsed / seg.seconds;
    final onColor = Colors.white;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _stopEarly();
      },
      child: Scaffold(
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                color,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.35), color),
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
                      Text(
                        widget.plan.name,
                        style: context.text.titleMedium?.copyWith(color: onColor),
                      ),
                      const Spacer(),
                      Text(
                        'Set ${_index + 1}/${_timeline.length}',
                        style: context.text.labelMedium?.copyWith(color: onColor),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    seg.label.toUpperCase(),
                    style: context.text.headlineSmall?.copyWith(
                      color: onColor,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  ProgressRing(
                    value: phaseProgress,
                    size: 220,
                    stroke: 14,
                    color: onColor,
                    trackColor: Colors.white.withValues(alpha: 0.25),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '$remaining',
                          style: context.text.displayLarge?.copyWith(
                            color: onColor,
                            fontSize: 76,
                          ),
                        ),
                        Text(
                          'seconds',
                          style: context.text.labelMedium?.copyWith(
                            color: onColor.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Insets.md),
                  HenFigure(
                    asset: seg.isEffort
                        ? Artwork.henSprinter
                        : Artwork.henHappy,
                    size: 72,
                    idle: false,
                  ),
                  const Spacer(),
                  if (_index < _timeline.length - 1)
                    Text(
                      'Next: ${_timeline[_index + 1].label} · ${_timeline[_index + 1].seconds}s',
                      style: context.text.bodyMedium?.copyWith(
                        color: onColor.withValues(alpha: 0.85),
                      ),
                    ),
                  const SizedBox(height: Insets.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _circle(
                        icon: Icons.stop_rounded,
                        bg: Colors.white.withValues(alpha: 0.18),
                        fg: onColor,
                        size: 60,
                        onTap: _stopEarly,
                      ),
                      _circle(
                        icon: _paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        bg: Colors.white,
                        fg: color,
                        size: 82,
                        onTap: () {
                          setState(() => _paused = !_paused);
                          final run = context.read<RunTracker>();
                          _paused ? run.pauseRun() : run.resumeRun();
                        },
                      ),
                      _circle(
                        icon: Icons.skip_next_rounded,
                        bg: Colors.white.withValues(alpha: 0.18),
                        fg: onColor,
                        size: 60,
                        onTap: () => setState(() {
                          if (_index >= _timeline.length - 1) {
                            _finish();
                          } else {
                            _index++;
                            _phaseElapsed = 0;
                          }
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle({
    required IconData icon,
    required Color bg,
    required Color fg,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Icon(icon, color: fg, size: size * 0.42),
      ),
    );
  }
}
