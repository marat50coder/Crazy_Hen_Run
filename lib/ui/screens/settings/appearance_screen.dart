import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../state/app_state.dart';
import '../../widgets/hen.dart';
import '../../widgets/progress.dart';
import '../../widgets/surfaces.dart';

/// Theme picker with a live preview card at the top — the only screen in the
/// app that mirrors its own controls back at you.
class AppearanceScreen extends StatelessWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          SoftCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color.alphaBlend(c.accent.withValues(alpha: 0.18), c.surface),
                c.surface,
              ],
            ),
            child: Row(
              children: <Widget>[
                HenBadge(asset: AppAssets.henRunner, size: 62, tint: c.accent),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Live preview', style: context.text.labelSmall),
                      Text('Morning run', style: context.text.titleMedium),
                      const SizedBox(height: 8),
                      TrackBar(value: 0.68, height: 8),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ProgressRing(
                  value: 0.68,
                  size: 52,
                  stroke: 6,
                  child: Text('68', style: context.text.labelMedium),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(title: 'Theme'),
          Row(
            children: <Widget>[
              _ThemeOption(
                mode: ThemeMode.light,
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: app.themeMode == ThemeMode.light,
                onTap: () => app.setThemeMode(ThemeMode.light),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                mode: ThemeMode.dark,
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: app.themeMode == ThemeMode.dark,
                onTap: () => app.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ThemeOption(
                mode: ThemeMode.system,
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                selected: app.themeMode == ThemeMode.system,
                onTap: () => app.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionHeader(
            title: 'Accent colour',
            subtitle: 'Used for buttons, rings and highlights',
          ),
          SoftCard(
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              children: List<Widget>.generate(HabitPalette.swatches.length, (i) {
                final tone = HabitPalette.at(i);
                final selected = i == app.accentIndex;
                return GestureDetector(
                  onTap: () => app.setAccentIndex(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: tone,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? c.textPrimary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.mode,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: selected ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: selected ? c.accent : c.outline),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: selected ? c.accent : c.textSecondary),
              const SizedBox(height: 8),
              Text(
                label,
                style: context.text.labelMedium?.copyWith(
                  color: selected ? c.accent : c.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
