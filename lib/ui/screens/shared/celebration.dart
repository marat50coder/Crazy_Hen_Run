import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/achievement.dart';
import '../../widgets/hen.dart';

Future<void> showAchievementCelebration(
  BuildContext context,
  Achievement achievement,
) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Achievement unlocked',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (_, _, _) => _CelebrationDialog(achievement: achievement),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

class _CelebrationDialog extends StatefulWidget {
  const _CelebrationDialog({required this.achievement});

  final Achievement achievement;

  @override
  State<_CelebrationDialog> createState() => _CelebrationDialogState();
}

class _CelebrationDialogState extends State<_CelebrationDialog> {
  late final ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 2))..play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final a = widget.achievement;

    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.lg),
            child: Container(
              padding: const EdgeInsets.all(Insets.lg),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Corners.xl),
                border: Border.all(color: c.outline),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const HenFigure(asset: Artwork.henHappy, size: 150),
                  const SizedBox(height: Insets.sm),
                  Text('Achievement unlocked', style: context.text.labelSmall),
                  const SizedBox(height: 6),
                  Text(
                    a.title,
                    textAlign: TextAlign.center,
                    style: context.text.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.description,
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium,
                  ),
                  const SizedBox(height: Insets.lg),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Keep running'),
                  ),
                ],
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: math.pi / 2,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.06,
          numberOfParticles: 14,
          maxBlastForce: 22,
          minBlastForce: 8,
          gravity: 0.24,
          colors: const <Color>[
            Meadow.lime,
            Meadow.corn,
            Meadow.comb,
            Meadow.sky,
            Meadow.lavender,
          ],
        ),
      ],
    );
  }
}
