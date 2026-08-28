import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../persistence/models/interval_plan.dart';
import '../../../domain/run_tracker.dart';
import '../../widgets/surfaces.dart';

class IntervalBuilderScreen extends StatefulWidget {
  const IntervalBuilderScreen({super.key, this.existing});

  final IntervalPlan? existing;

  @override
  State<IntervalBuilderScreen> createState() => _IntervalBuilderScreenState();
}

class _IntervalBuilderScreenState extends State<IntervalBuilderScreen> {
  late final TextEditingController _name;
  late List<IntervalSegment> _segments;
  late int _repeats;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? 'My interval plan');
    _segments = e != null
        ? List<IntervalSegment>.of(e.segments)
        : <IntervalSegment>[
            const IntervalSegment(label: 'Run', seconds: 60, intensity: 0.85),
            const IntervalSegment(label: 'Walk', seconds: 60, intensity: 0.25),
          ];
    _repeats = e?.repeats ?? 4;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _addSegment() {
    setState(() {
      _segments.add(const IntervalSegment(label: 'Segment', seconds: 60, intensity: 0.6));
    });
  }

  int get _totalSeconds =>
      _segments.fold<int>(0, (s, e) => s + e.seconds) * _repeats;

  Future<void> _save() async {
    if (_segments.isEmpty) return;
    final plan = IntervalPlan(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _name.text.trim().isEmpty ? 'Interval plan' : _name.text.trim(),
      segments: _segments,
      repeats: _repeats,
    );
    await context.read<RunTracker>().savePlan(plan);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await context.read<RunTracker>().deletePlan(widget.existing!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final m = _totalSeconds ~/ 60;
    final s = _totalSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'New plan' : 'Edit plan'),
        actions: <Widget>[
          if (widget.existing != null)
            IconButton(onPressed: _delete, icon: const Icon(Icons.delete_outline_rounded)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Insets.md),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check_rounded),
            label: Text('Save · ${m}m ${s.toString().padLeft(2, '0')}s'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.md, Insets.sm, Insets.md, Insets.md),
        children: <Widget>[
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Plan name'),
          ),
          const SizedBox(height: Insets.md),
          SoftCard(
            padding: const EdgeInsets.all(Insets.md),
            child: Row(
              children: <Widget>[
                const Icon(Icons.repeat_rounded, size: 18),
                const SizedBox(width: 8),
                Text('Repeat set', style: context.text.titleSmall),
                const Spacer(),
                _Stepper(
                  value: _repeats,
                  onChanged: (v) => setState(() => _repeats = v.clamp(1, 20)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          const SectionHeader(title: 'Segments'),
          ...List<Widget>.generate(_segments.length, (i) => _segmentCard(i)),
          const SizedBox(height: Insets.sm),
          OutlinedButton.icon(
            onPressed: _addSegment,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add segment'),
          ),
        ],
      ),
    );
  }

  Widget _segmentCard(int i) {
    final seg = _segments[i];
    return Padding(
      padding: const EdgeInsets.only(bottom: Insets.sm),
      child: SoftCard(
        padding: const EdgeInsets.all(Insets.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Color.lerp(Meadow.sky, Meadow.comb, seg.intensity),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: seg.label,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Label',
                    ),
                    onChanged: (v) => _segments[i] = seg.copyWith(label: v),
                  ),
                ),
                if (_segments.length > 1)
                  IconButton(
                    onPressed: () => setState(() => _segments.removeAt(i)),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
              ],
            ),
            Row(
              children: <Widget>[
                Text('${seg.seconds}s', style: context.text.labelMedium),
                Expanded(
                  child: Slider(
                    value: seg.seconds.toDouble(),
                    min: 10,
                    max: 600,
                    divisions: 59,
                    onChanged: (v) =>
                        setState(() => _segments[i] = seg.copyWith(seconds: (v ~/ 5) * 5)),
                  ),
                ),
              ],
            ),
            Row(
              children: <Widget>[
                Text(seg.isEffort ? 'Effort' : 'Recovery', style: context.text.labelMedium),
                Expanded(
                  child: Slider(
                    value: seg.intensity,
                    activeColor: Color.lerp(Meadow.sky, Meadow.comb, seg.intensity),
                    onChanged: (v) => setState(() => _segments[i] = seg.copyWith(intensity: v)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _btn(context, Icons.remove_rounded, () => onChanged(value - 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$value×', style: context.text.titleMedium),
        ),
        _btn(context, Icons.add_rounded, () => onChanged(value + 1)),
      ],
    );
  }

  Widget _btn(BuildContext context, IconData icon, VoidCallback onTap) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: c.outline),
        ),
        child: Icon(icon, size: 18, color: c.textPrimary),
      ),
    );
  }
}
