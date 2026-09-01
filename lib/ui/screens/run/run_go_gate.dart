import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/theme/palette.dart';
import '../../../persistence/models/run_goal.dart';
import '../../../persistence/models/run_type.dart';
import 'live_run_screen.dart';

/// Three-beat countdown before a live run so the phone can go in a pocket.
class RunGoGate extends StatefulWidget {
  const RunGoGate({
    super.key,
    required this.type,
    this.goal = RunGoal.open,
  });

  final RunType type;
  final RunGoal goal;

  @override
  State<RunGoGate> createState() => _RunGoGateState();
}

class _RunGoGateState extends State<RunGoGate> {
  static const List<String> _beats = <String>['3', '2', '1', 'GO'];

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    _timer = Timer.periodic(const Duration(milliseconds: 780), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (_index >= _beats.length - 1) {
      timer.cancel();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LiveRunScreen(type: widget.type, goal: widget.goal),
        ),
      );
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _index += 1);
  }

  @override
  Widget build(BuildContext context) {
    final beat = _beats[_index];
    final isGo = beat == 'GO';
    return Scaffold(
      backgroundColor: Meadow.forestDeep,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                widget.type.label,
                style: context.text.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              if (!widget.goal.isOpen) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  widget.goal.liveLabel,
                  style: context.text.labelLarge?.copyWith(color: Meadow.go),
                ),
              ],
              const SizedBox(height: Insets.md),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  beat,
                  key: ValueKey<String>(beat),
                  style: context.text.displayLarge?.copyWith(
                    color: isGo ? Meadow.go : Colors.white,
                    fontSize: isGo ? 72 : 96,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: Insets.lg),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: context.text.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
