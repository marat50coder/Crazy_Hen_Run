import 'package:flutter/material.dart';

import '../../foundation/constants/artwork.dart';

/// The distinct flavours of run the app can guide and record. Each type
/// carries its own colour, mascot pose and rough MET value used for the
/// calorie estimate, so every run *looks* and *counts* differently.
enum RunType {
  free(
    'Free Run',
    'Just you and the road. No rules, no targets — let the hen set the pace.',
    Icons.directions_run_rounded,
    0xFF2E9E5B,
    Artwork.henRunner,
    8.5,
    'Open pace',
  ),
  interval(
    'Intervals',
    'Alternate hard efforts with easy jogs. Builds speed and grit fast.',
    Icons.speed_rounded,
    0xFFF2683C,
    Artwork.henSprinter,
    11.5,
    'Work / rest',
  ),
  tempo(
    'Tempo',
    'Comfortably hard, held steady. Your engine room for race pace.',
    Icons.local_fire_department_rounded,
    0xFFE0483D,
    Artwork.henSprinter,
    10.0,
    'Steady hard',
  ),
  long(
    'Long Run',
    'Slow, patient miles. This is where the hen grows real endurance.',
    Icons.route_rounded,
    0xFF3E7BC2,
    Artwork.henStanding,
    9.0,
    'Endurance',
  ),
  recovery(
    'Recovery',
    'Feather-light shakeout to loosen the legs and stay consistent.',
    Icons.self_improvement_rounded,
    0xFF8A6FE0,
    Artwork.henHappy,
    6.0,
    'Easy day',
  ),
  sprint(
    'Sprint',
    'Short, explosive bursts. Chase the fox and empty the tank.',
    Icons.bolt_rounded,
    0xFFF2A93B,
    Artwork.henSprinter,
    13.0,
    'All out',
  );

  const RunType(
    this.label,
    this.blurb,
    this.icon,
    this.colorValue,
    this.henAsset,
    this.met,
    this.tag,
  );

  final String label;
  final String blurb;
  final IconData icon;
  final int colorValue;
  final String henAsset;

  /// Metabolic equivalent used for the rough calorie estimate.
  final double met;

  /// Short label shown on chips.
  final String tag;

  Color get color => Color(colorValue);

  static RunType byName(String name) =>
      RunType.values.firstWhere((t) => t.name == name, orElse: () => RunType.free);
}
