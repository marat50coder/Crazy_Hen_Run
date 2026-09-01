import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/run_session.dart';
import '../../widgets/run_widgets.dart';

/// A poster-shaped card meant to be captured to a PNG and shared. It is
/// painted off-screen from [RunSummaryScreen] so users can post their run
/// like any other fitness app.
class RunShareCard extends StatelessWidget {
  const RunShareCard({super.key, required this.run});

  final RunSession run;

  static const double kWidth = 720;
  static const double kHeight = 1000;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('EEEE, d MMMM').format(run.startedAt);
    final start = run.type.color;
    final end = Color.alphaBlend(Colors.black.withValues(alpha: 0.35), start);
    final white = Colors.white;
    final wSoft = white.withValues(alpha: 0.75);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: kWidth,
        height: kHeight,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[start, end],
            ),
            borderRadius: BorderRadius.circular(48),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(52, 60, 52, 52),
            child: DefaultTextStyle(
              style: TextStyle(color: white, fontFamily: 'SpaceGrotesk'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(run.type.icon, color: white, size: 40),
                      const SizedBox(width: 14),
                      Text(
                        run.type.label,
                        style: TextStyle(
                          color: white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'HENYARD',
                        style: TextStyle(
                          color: wSoft,
                          fontSize: 14,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    run.distanceLabel,
                    style: TextStyle(
                      color: white,
                      fontSize: 132,
                      fontWeight: FontWeight.w800,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    date,
                    style: TextStyle(
                      color: wSoft,
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: <Widget>[
                      Expanded(child: _stat('Duration', run.durationLabel, white, wSoft)),
                      Expanded(child: _stat('Pace', run.paceLabel.replaceAll(' /km', '/km'), white, wSoft)),
                      Expanded(child: _stat('Kcal', '${run.calories}', white, wSoft)),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(Corners.lg),
                    ),
                    child: RunTrace(
                      samples: run.cadence,
                      color: Colors.white,
                      height: 120,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: <Widget>[
                      _pill('${run.steps} steps', wSoft),
                      const SizedBox(width: 10),
                      _pill('${run.avgCadenceSpm.round()} spm', wSoft),
                      const SizedBox(width: 10),
                      _pill('${run.speedKmh.toStringAsFixed(1)} km/h', wSoft),
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

  Widget _stat(String label, String value, Color primary, Color soft) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: soft,
            fontSize: 14,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: primary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _pill(String text, Color soft) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: soft,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
