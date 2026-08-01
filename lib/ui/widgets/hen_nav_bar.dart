import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

class HenNavItem {
  const HenNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Floating pill navigation. The active item expands into a labelled capsule,
/// which keeps the bar compact without hiding what the tabs mean.
class HenNavBar extends StatelessWidget {
  const HenNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
  });

  final List<HenNavItem> items;
  final int index;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(color: c.outline),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: c.shadow,
              blurRadius: 28,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(items.length, (i) {
            final item = items[i];
            final selected = i == index;
            return Expanded(
              flex: selected ? 3 : 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  height: 46,
                  decoration: BoxDecoration(
                    color: selected ? c.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        selected ? item.activeIcon : item.icon,
                        size: 21,
                        color: selected
                            ? _onAccent(c.accent)
                            : c.textSecondary,
                      ),
                      if (selected) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.label,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelMedium?.copyWith(
                              color: _onAccent(c.accent),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  static Color _onAccent(Color accent) =>
      accent.computeLuminance() > 0.55 ? const Color(0xFF102117) : Colors.white;
}
