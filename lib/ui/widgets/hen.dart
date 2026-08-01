import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_theme.dart';

/// The hen artwork with an idle bob so the character never feels like a
/// static sticker.
class HenFigure extends StatelessWidget {
  const HenFigure({
    super.key,
    required this.asset,
    this.size = 140,
    this.idle = true,
    this.tilt = 0,
  });

  final String asset;
  final double size;

  /// Whether the idle bobbing loop should run.
  final bool idle;

  final double tilt;

  @override
  Widget build(BuildContext context) {
    Widget image = Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    if (tilt != 0) {
      image = Transform.rotate(angle: tilt, child: image);
    }
    if (!idle) return image;

    return image
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -6, duration: 1800.ms, curve: Curves.easeInOut)
        .then()
        .scaleXY(begin: 1, end: 1.01, duration: 1800.ms);
  }
}

/// Round badge that frames the hen on cards and headers.
class HenBadge extends StatelessWidget {
  const HenBadge({
    super.key,
    required this.asset,
    this.size = 64,
    this.tint,
    this.idle = false,
  });

  final String asset;
  final double size;
  final Color? tint;
  final bool idle;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = tint ?? c.accent;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            tone.withValues(alpha: 0.28),
            tone.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: 0.35), width: 1.2),
      ),
      child: HenFigure(asset: asset, size: size * 0.8, idle: idle),
    );
  }
}

/// Daily hero: a lane of track that the hen advances along as habits close.
class RunTrackHero extends StatelessWidget {
  const RunTrackHero({
    super.key,
    required this.progress,
    required this.henAsset,
    this.height = 108,
    this.caption,
  });

  final double progress;
  final String henAsset;
  final double height;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          const henSize = 64.0;
          final travel = (width - henSize - 12).clamp(0.0, double.infinity);

          return Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    gradient: LinearGradient(
                      colors: <Color>[
                        c.surfaceMuted,
                        c.accent.withValues(alpha: 0.16),
                      ],
                    ),
                    border: Border.all(color: c.outline),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _LaneMarks(color: c.outlineStrong),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: clamped),
                  duration: const Duration(milliseconds: 750),
                  curve: Curves.easeOutCubic,
                  builder: (context, animated, _) => Container(
                    height: 44,
                    width: (width * animated).clamp(0.0, width),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      gradient: LinearGradient(
                        colors: <Color>[
                          c.accent.withValues(alpha: 0.85),
                          c.accent.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  width: 6,
                  height: 28,
                  decoration: BoxDecoration(
                    color: c.textPrimary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: clamped),
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutCubic,
                builder: (context, animated, _) => Positioned(
                  left: travel * animated,
                  bottom: 26,
                  child: HenFigure(asset: henAsset, size: henSize),
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

class _LaneMarks extends StatelessWidget {
  const _LaneMarks({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / 26).floor().clamp(1, 60);
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List<Widget>.generate(
            count,
            (_) => Container(
              width: 14,
              height: 3,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Shared empty state: curious hen, headline, hint and an optional action.
class HenEmptyState extends StatelessWidget {
  const HenEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.asset = AppAssets.henCurious,
    this.action,
    this.henSize = 180,
  });

  final String title;
  final String message;
  final String asset;
  final Widget? action;
  final double henSize;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            HenFigure(asset: asset, size: henSize),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
