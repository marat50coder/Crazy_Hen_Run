import 'dart:ui';

import 'package:flutter/material.dart';

import '../../foundation/theme/palette.dart';
import '../../foundation/theme/henyard_theme.dart';

/// The standard raised panel used across the app: flat fill, hairline border,
/// very soft shadow. Everything else is composed on top of it.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.md),
    this.radius = Corners.lg,
    this.color,
    this.border = true,
    this.onTap,
    this.elevated = true,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final bool border;
  final VoidCallback? onTap;
  final bool elevated;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final shape = BorderRadius.circular(radius);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: gradient == null ? (color ?? c.surface) : null,
          gradient: gradient,
          borderRadius: shape,
          border: border ? Border.all(color: c.outline) : null,
          boxShadow: elevated
              ? <BoxShadow>[
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                    spreadRadius: -8,
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: shape,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Frosted panel used on top of photographic artwork.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Insets.md),
    this.radius = Corners.lg,
    this.tint,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? c.surface.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Small rounded label. Used for categories, units and metadata.
class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    this.icon,
    this.color,
    this.dense = false,
  });

  final String label;
  final IconData? icon;
  final Color? color;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = color ?? c.accent;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 11,
        vertical: dense ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(Corners.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 14, color: tone),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: (dense ? context.text.labelSmall : context.text.labelMedium)
                ?.copyWith(color: tone, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.padding = const EdgeInsets.only(bottom: Insets.sm),
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: context.text.titleMedium),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: context.text.bodySmall),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A dotted divider that echoes the road markings from the artwork.
class RoadDivider extends StatelessWidget {
  const RoadDivider({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? context.palette.outlineStrong;
    return SizedBox(
      height: 3,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = (constraints.maxWidth / 12).floor().clamp(1, 200);
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List<Widget>.generate(
              count,
              (_) => Container(
                width: 6,
                height: 3,
                decoration: BoxDecoration(
                  color: tone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
