import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/run_session.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/hen.dart';
import '../../widgets/run_widgets.dart';
import '../../widgets/surfaces.dart';
import 'run_share_card.dart';

class RunSummaryScreen extends StatefulWidget {
  const RunSummaryScreen({super.key, required this.runId});

  final String runId;

  @override
  State<RunSummaryScreen> createState() => _RunSummaryScreenState();
}

class _RunSummaryScreenState extends State<RunSummaryScreen> {
  int _feeling = 3;
  final TextEditingController _note = TextEditingController();
  bool _initialised = false;
  bool _sharing = false;
  final GlobalKey _shareKey = GlobalKey();

  static const List<({IconData icon, String label})> _feelings = <({IconData icon, String label})>[
    (icon: Icons.sentiment_very_dissatisfied_rounded, label: 'Rough'),
    (icon: Icons.sentiment_dissatisfied_rounded, label: 'Meh'),
    (icon: Icons.sentiment_neutral_rounded, label: 'Okay'),
    (icon: Icons.sentiment_satisfied_rounded, label: 'Good'),
    (icon: Icons.sentiment_very_satisfied_rounded, label: 'Great'),
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  RunSession? _find(RunTracker run) {
    for (final r in run.runs) {
      if (r.id == widget.runId) return r;
    }
    return null;
  }

  Future<void> _save(RunSession run) async {
    final rs = context.read<RunTracker>();
    await rs.updateRun(run.copyWith(feeling: _feeling, note: _note.text.trim()));
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Future<void> _share(RunSession run) async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      final boundary =
          _shareKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.4);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/henyard_run_${run.id}.png',
      );
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await Share.shareXFiles(
        <XFile>[XFile(file.path, mimeType: 'image/png')],
        text: 'Today: ${run.distanceLabel} · ${run.durationLabel} — Crazy Hen Run',
      );
    } on PlatformException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing is not available on this device')),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.watch<RunTracker>();
    final run = _find(rs);
    final c = context.palette;

    if (run == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_initialised) {
      _feeling = run.feeling;
      _note.text = run.note;
      _initialised = true;
    }

    return Scaffold(
      body: Stack(
        children: <Widget>[
          _offstageShareCanvas(run),
          _content(rs, run, c),
        ],
      ),
    );
  }

  Widget _offstageShareCanvas(RunSession run) {
    return Positioned(
      left: -10000,
      top: -10000,
      child: RepaintBoundary(
        key: _shareKey,
        child: MediaQuery(
          data: const MediaQueryData(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RunShareCard(run: run),
          ),
        ),
      ),
    );
  }

  Widget _content(RunTracker rs, RunSession run, Palette c) {
    return ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + Insets.lg,
              left: Insets.lg,
              right: Insets.lg,
              bottom: Insets.xl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  run.type.color,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.25), run.type.color),
                ],
              ),
            ),
            child: Column(
              children: <Widget>[
                HenFigure(asset: run.type.henAsset, size: 96)
                    .animate()
                    .scale(duration: 420.ms, curve: Curves.easeOutBack),
                const SizedBox(height: Insets.sm),
                Text(
                  'Run complete!',
                  style: context.text.headlineMedium?.copyWith(color: Colors.white),
                ),
                Text(
                  '${run.type.label} · ${run.durationLabel}',
                  style: context.text.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                if (rs.isPersonalBest(run)) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Personal best · ${run.distanceLabel}',
                      style: context.text.labelMedium?.copyWith(color: Meadow.go),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Insets.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SoftCard(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: MetricTile(
                          value: run.distanceLabel,
                          label: 'Distance',
                          icon: Icons.route_rounded,
                          color: run.type.color,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: run.paceLabel.replaceAll(' /km', ''),
                          label: 'Pace /km',
                          icon: Icons.speed_rounded,
                          color: Meadow.sky,
                        ),
                      ),
                      Expanded(
                        child: MetricTile(
                          value: '${run.calories}',
                          label: 'Kcal',
                          icon: Icons.local_fire_department_rounded,
                          color: Meadow.comb,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.md),
                Text('Effort trace', style: context.text.labelSmall),
                const SizedBox(height: 8),
                RunTrace(
                  samples: run.cadence,
                  color: run.type.color,
                  height: 120,
                ),
                const SizedBox(height: Insets.md),
                SoftCard(
                  padding: const EdgeInsets.all(Insets.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      _mini('${run.steps}', 'steps'),
                      _mini(run.avgCadenceSpm.round().toString(), 'spm'),
                      _mini(run.speedKmh.toStringAsFixed(1), 'km/h'),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                Text('How did it feel?', style: context.text.titleMedium),
                const SizedBox(height: Insets.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List<Widget>.generate(_feelings.length, (i) {
                    final selected = _feeling == i + 1;
                    return GestureDetector(
                      onTap: () => setState(() => _feeling = i + 1),
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: selected ? run.type.color : c.surfaceMuted,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected ? run.type.color : c.outline,
                              ),
                            ),
                            child: Icon(
                              _feelings[i].icon,
                              color: selected ? Colors.white : c.textSecondary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(_feelings[i].label, style: context.text.labelSmall),
                        ],
                      ),
                    );
                  }),
                ),
                const SizedBox(height: Insets.lg),
                TextField(
                  controller: _note,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Notes — how was the route, the weather, your legs?',
                  ),
                ),
                const SizedBox(height: Insets.lg),
                FilledButton.icon(
                  onPressed: () => _save(run),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Save run'),
                ),
                const SizedBox(height: Insets.sm),
                OutlinedButton.icon(
                  onPressed: _sharing ? null : () => _share(run),
                  icon: _sharing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share_rounded),
                  label: Text(_sharing ? 'Preparing…' : 'Share summary'),
                ),
                const SizedBox(height: Insets.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  child: const Text('Skip for now'),
                ),
              ],
            ),
          ),
        ],
      );
  }

  Widget _mini(String value, String label) => Column(
        children: <Widget>[
          Text(value, style: context.text.titleLarge),
          Text(label, style: context.text.labelSmall),
        ],
      );
}
