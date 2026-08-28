/// One phase inside an interval workout: a labelled block of seconds at a
/// given intensity (0 = walk/rest, 1 = hard effort).
class IntervalSegment {
  const IntervalSegment({
    required this.label,
    required this.seconds,
    required this.intensity,
  });

  final String label;
  final int seconds;

  /// 0..1 — drives colour, the hen's speed and the calorie weighting.
  final double intensity;

  bool get isEffort => intensity >= 0.5;

  IntervalSegment copyWith({String? label, int? seconds, double? intensity}) =>
      IntervalSegment(
        label: label ?? this.label,
        seconds: seconds ?? this.seconds,
        intensity: intensity ?? this.intensity,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'seconds': seconds,
        'intensity': intensity,
      };

  factory IntervalSegment.fromJson(Map<String, dynamic> json) =>
      IntervalSegment(
        label: json['label'] as String? ?? 'Segment',
        seconds: (json['seconds'] as num).toInt(),
        intensity: (json['intensity'] as num).toDouble(),
      );
}

/// A repeatable set of segments — the recipe for a guided interval run.
class IntervalPlan {
  const IntervalPlan({
    required this.id,
    required this.name,
    required this.segments,
    this.repeats = 1,
  });

  final String id;
  final String name;
  final List<IntervalSegment> segments;
  final int repeats;

  /// Fully expanded timeline (segments × repeats).
  List<IntervalSegment> get timeline => <IntervalSegment>[
        for (var r = 0; r < repeats; r++) ...segments,
      ];

  int get totalSeconds =>
      segments.fold<int>(0, (sum, s) => sum + s.seconds) * repeats;

  int get effortSeconds => segments
          .where((s) => s.isEffort)
          .fold<int>(0, (sum, s) => sum + s.seconds) *
      repeats;

  String get durationLabel {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  IntervalPlan copyWith({
    String? name,
    List<IntervalSegment>? segments,
    int? repeats,
  }) =>
      IntervalPlan(
        id: id,
        name: name ?? this.name,
        segments: segments ?? this.segments,
        repeats: repeats ?? this.repeats,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'repeats': repeats,
        'segments': segments.map((s) => s.toJson()).toList(),
      };

  factory IntervalPlan.fromJson(Map<String, dynamic> json) => IntervalPlan(
        id: json['id'] as String,
        name: json['name'] as String? ?? 'Interval plan',
        repeats: (json['repeats'] as num?)?.toInt() ?? 1,
        segments: (json['segments'] as List<dynamic>? ?? const <dynamic>[])
            .map((e) => IntervalSegment.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );

  /// A few ready-made plans so the feature is useful on day one.
  static List<IntervalPlan> presets() => <IntervalPlan>[
        const IntervalPlan(
          id: 'preset-beginner',
          name: 'Run / Walk starter',
          repeats: 6,
          segments: <IntervalSegment>[
            IntervalSegment(label: 'Run', seconds: 60, intensity: 0.8),
            IntervalSegment(label: 'Walk', seconds: 90, intensity: 0.2),
          ],
        ),
        const IntervalPlan(
          id: 'preset-classic',
          name: 'Classic 4×4',
          repeats: 4,
          segments: <IntervalSegment>[
            IntervalSegment(label: 'Hard', seconds: 240, intensity: 0.95),
            IntervalSegment(label: 'Easy', seconds: 180, intensity: 0.35),
          ],
        ),
        const IntervalPlan(
          id: 'preset-speed',
          name: 'Speed pyramid',
          repeats: 1,
          segments: <IntervalSegment>[
            IntervalSegment(label: 'Surge', seconds: 30, intensity: 1),
            IntervalSegment(label: 'Jog', seconds: 60, intensity: 0.3),
            IntervalSegment(label: 'Surge', seconds: 45, intensity: 1),
            IntervalSegment(label: 'Jog', seconds: 60, intensity: 0.3),
            IntervalSegment(label: 'Surge', seconds: 60, intensity: 1),
            IntervalSegment(label: 'Jog', seconds: 90, intensity: 0.3),
          ],
        ),
      ];
}
