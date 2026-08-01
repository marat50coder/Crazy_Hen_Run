import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/day_key.dart';
import '../../../data/models/journal_entry.dart';
import '../../../state/app_state.dart';
import '../../widgets/surfaces.dart';

/// Mood-first entry form: pick the face, set the energy, then write.
class JournalEditorScreen extends StatefulWidget {
  const JournalEditorScreen({super.key, required this.day});

  final DateTime day;

  @override
  State<JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<JournalEditorScreen> {
  late final TextEditingController _note;
  late Mood _mood;
  late int _energy;
  late bool _existing;

  @override
  void initState() {
    super.initState();
    final entry = context.read<AppState>().journalFor(widget.day);
    _existing = entry != null;
    _note = TextEditingController(text: entry?.note ?? '');
    _mood = entry?.mood ?? Mood.okay;
    _energy = entry?.energy ?? 3;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    await app.saveJournal(
      JournalEntry(
        dayKey: DayKey.of(widget.day),
        mood: _mood,
        note: _note.text.trim(),
        energy: _energy,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal'),
        actions: <Widget>[
          if (_existing)
            IconButton(
              tooltip: 'Delete entry',
              onPressed: () async {
                await context
                    .read<AppState>()
                    .deleteJournal(DayKey.of(widget.day));
                if (!context.mounted) return;
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(DayKey.pretty(widget.day), style: context.text.headlineSmall),
          const SizedBox(height: 4),
          Text('How did the day actually feel?', style: context.text.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: Mood.values.map((mood) {
              final selected = mood == _mood;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => setState(() => _mood = mood),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutBack,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected
                            ? mood.color.withValues(alpha: 0.18)
                            : c.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(
                          color: selected ? mood.color : c.outline,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Text(
                            mood.emoji,
                            style: TextStyle(fontSize: selected ? 26 : 22),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall?.copyWith(
                              color: selected ? mood.color : c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.battery_charging_full_rounded, color: c.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Energy level', style: context.text.titleSmall),
                    ),
                    Text('$_energy/5', style: context.text.titleSmall),
                  ],
                ),
                Slider(
                  value: _energy.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (v) => setState(() => _energy = v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText:
                  'What worked, what got in the way, what you will change tomorrow…',
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: _save,
            child: Text(_existing ? 'Update entry' : 'Save entry'),
          ),
        ],
      ),
    );
  }
}
