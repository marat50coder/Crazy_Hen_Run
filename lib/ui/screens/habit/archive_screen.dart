import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/utils/day_key.dart';
import '../../../domain/hen_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<HenState>();
    final c = context.palette;
    final archived = app.archivedHabits;

    return Scaffold(
      appBar: AppBar(title: const Text('Archive')),
      body: archived.isEmpty
          ? const HenEmptyState(
              title: 'Archive is empty',
              message:
                  'Habits you retire end up here. Their history is kept, so you can bring one back at any time.',
              asset: Artwork.henStanding,
              henSize: 160,
            )
          : ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Insets.md,
                0,
                Insets.md,
                Insets.xxl,
              ),
              itemCount: archived.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final habit = archived[i];
                final tone = HabitSwatches.at(habit.colorIndex);
                final completions = app.completionCountFor(habit);

                return SoftCard(
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: tone.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(Corners.sm),
                        ),
                        child: Icon(
                          habit.category.icon,
                          size: 20,
                          color: tone.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              habit.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.titleSmall,
                            ),
                            Text(
                              '$completions closed · started ${DayKey.medium(habit.createdAt)}',
                              style: context.text.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Restore',
                        onPressed: () => app.setArchived(habit.id, false),
                        icon: Icon(Icons.unarchive_rounded, color: c.accent),
                      ),
                      IconButton(
                        tooltip: 'Delete forever',
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete forever?'),
                              content: Text(
                                '"${habit.title}" and all of its history will be removed.',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: c.danger,
                                    minimumSize: const Size(110, 46),
                                  ),
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            await app.deleteHabit(habit.id);
                          }
                        },
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
