import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../persistence/models/journal_entry.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';
import 'journal_editor_screen.dart';

/// Timeline layout with a vertical rail, so it reads like a diary rather than
/// a list of cards.
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;

    final entries = app.journal.values.toList()
      ..sort((a, b) => b.dayKey.compareTo(a.dayKey));

    final moodAverage = entries.isEmpty
        ? 0.0
        : entries.fold<int>(0, (a, e) => a + e.mood.score) / entries.length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => JournalEditorScreen(day: DayKey.today()),
          ),
        ),
        backgroundColor: c.accent,
        foregroundColor:
            c.accent.computeLuminance() > 0.55 ? c.textPrimary : Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write today'),
      ),
      appBar: AppBar(title: const Text('Journal')),
      body: entries.isEmpty
          ? HenEmptyState(
              title: 'No entries yet',
              message:
                  'A couple of lines a day is enough. Later they explain why some weeks went well and others did not.',
              asset: Artwork.henCoach,
              henSize: 170,
              action: FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => JournalEditorScreen(day: DayKey.today()),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Write the first one'),
              ),
            )
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                0,
                Insets.md,
                120,
              ),
              children: <Widget>[
                SoftCard(
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('${entries.length}', style: context.text.displaySmall),
                            Text('entries written', style: context.text.labelSmall),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 40, color: c.outline),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              _moodFor(moodAverage).emoji,
                              style: const TextStyle(fontSize: 30),
                            ),
                            Text(
                              'average mood',
                              style: context.text.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Insets.lg),
                ...List<Widget>.generate(entries.length, (i) {
                  final entry = entries[i];
                  return _TimelineRow(
                    entry: entry,
                    isLast: i == entries.length - 1,
                  );
                }),
              ],
            ),
    );
  }

  static Mood _moodFor(double average) {
    final index = (average.round() - 1).clamp(0, Mood.values.length - 1);
    return Mood.values[index];
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.entry, required this.isLast});

  final JournalEntry entry;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final day = DayKey.parse(entry.dayKey);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          SizedBox(
            width: 54,
            child: Column(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: entry.mood.color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    entry.mood.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: c.outline),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
              child: SoftCard(
                padding: const EdgeInsets.all(14),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => JournalEditorScreen(day: day),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            DayKey.pretty(day),
                            style: context.text.titleSmall,
                          ),
                        ),
                        TagChip(
                          label: 'Energy ${entry.energy}/5',
                          color: entry.mood.color,
                          dense: true,
                        ),
                      ],
                    ),
                    if (entry.note.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        entry.note,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
