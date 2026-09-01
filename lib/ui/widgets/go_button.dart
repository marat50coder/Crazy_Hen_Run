import 'package:flutter/material.dart';

import '../../foundation/theme/palette.dart';

/// Full-width stadium button used for Start / Discard — same green as the
/// play triangle on the live-run control, white label so it stays readable.
class GoButton extends StatelessWidget {
  const GoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.play_arrow_rounded,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  static const Color fill = Meadow.go;
  static const Color ink = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 26, color: ink),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: ink,
          disabledBackgroundColor: fill.withValues(alpha: 0.45),
          disabledForegroundColor: ink.withValues(alpha: 0.8),
          textStyle: context.text.labelLarge?.copyWith(color: ink),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
