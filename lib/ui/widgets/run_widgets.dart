import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/run_type.dart';
import 'hen.dart';

/// Stylised effort trace: a smooth curve built from normalised cadence samples
/// (0..1). This is deliberately *not* a map — it visualises how the run's
/// intensity rose and fell over time, so it works fully offline with no GPS.
class RunTrace extends StatelessWidget {
  const RunTrace({
    super.key,
    required this.samples,
    required this.color,
    this.height = 120,
    this.showHen = false,
    this.henAsset,
  });

  final List<double> samples;
  final Color color;
  final double height;
  final bool showHen;
  final String? henAsset;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final data = samples.isEmpty ? <double>[0.15, 0.15] : samples;
          final lastX = _lastX(data, w);
          final lastY = h - (data.last.clamp(0.0, 1.0)) * (h - 18) - 6;

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        c.surfaceMuted,
                        c.surfaceMuted.withValues(alpha: 0.4),
                      ],
                    ),
                    border: Border.all(color: c.outline),
                  ),
                ),
              ),
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: CustomPaint(
                    painter: _TracePainter(
                      samples: data,
                      color: color,
                      grid: c.outline,
                    ),
                  ),
                ),
              ),
              if (showHen && henAsset != null)
                Positioned(
                  left: (lastX - 20).clamp(0.0, w - 40),
                  top: (lastY - 34).clamp(0.0, h - 40),
                  child: HenFigure(asset: henAsset!, size: 40, idle: false),
                ),
            ],
          );
        },
      ),
    );
  }

  double _lastX(List<double> data, double w) {
    if (data.length < 2) return w;
    return w;
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.samples,
    required this.color,
    required this.grid,
  });

  final List<double> samples;
  final Color color;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = grid.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final n = samples.length;
    if (n == 0) return;
    final dx = n == 1 ? size.width : size.width / (n - 1);
    double xy(int i) => i * dx;
    double yy(int i) =>
        size.height - samples[i].clamp(0.0, 1.0) * (size.height - 16) - 8;

    final path = Path()..moveTo(0, yy(0));
    for (var i = 1; i < n; i++) {
      final prevX = xy(i - 1);
      final prevY = yy(i - 1);
      final curX = xy(i);
      final curY = yy(i);
      final midX = (prevX + curX) / 2;
      path.cubicTo(midX, prevY, midX, curY, curX, curY);
    }

    final fill = Path.from(path)
      ..lineTo(xy(n - 1), size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[color.withValues(alpha: 0.32), color.withValues(alpha: 0.02)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );

    // Head dot.
    canvas.drawCircle(
      Offset(xy(n - 1), yy(n - 1)),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.samples.length != samples.length || old.color != color;
}

/// Compact metric readout used on the run hub, live screen and summaries.
class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color,
    this.big = false,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color? color;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = color ?? c.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: big ? 20 : 16, color: tone),
          const SizedBox(height: 6),
        ],
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: (big ? context.text.displaySmall : context.text.titleLarge)
              ?.copyWith(letterSpacing: -0.5),
        ),
        const SizedBox(height: 2),
        Text(
          label.toUpperCase(),
          style: context.text.labelSmall?.copyWith(letterSpacing: 0.8),
        ),
      ],
    );
  }
}

/// Selectable chip representing a run type.
class RunTypeChip extends StatelessWidget {
  const RunTypeChip({
    super.key,
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final RunType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? type.color : c.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: selected ? type.color : c.outline,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              type.icon,
              size: 17,
              color: selected ? Colors.white : type.color,
            ),
            const SizedBox(width: 7),
            Text(
              type.label,
              style: context.text.labelMedium?.copyWith(
                color: selected ? Colors.white : c.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A decorative running track with the hen bobbing along it — dropped onto
/// screens so the mascot shows up everywhere without repeating a static image.
class HenRunStrip extends StatelessWidget {
  const HenRunStrip({
    super.key,
    required this.progress,
    required this.henAsset,
    this.color,
    this.height = 74,
    this.caption,
  });

  final double progress;
  final String henAsset;
  final Color? color;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = color ?? c.accent;
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          const hen = 52.0;
          final travel = (w - hen).clamp(0.0, double.infinity);
          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 6,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: tone.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: clamped),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, a, _) => Container(
                    height: 8,
                    width: (w * a).clamp(0.0, w),
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, a, _) => Positioned(
                  left: travel * a,
                  bottom: 8,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationZ(-0.04 * math.sin(a * math.pi * 6)),
                    child: HenFigure(asset: henAsset, size: hen),
                  ),
                ),
              ),
              if (caption != null)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Text(caption!, style: context.text.labelSmall),
                ),
            ],
          );
        },
      ),
    );
  }
}
