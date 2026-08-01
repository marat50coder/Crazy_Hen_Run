import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';

/// First screen of the app.
///
/// The bar starts completely empty and advances through discrete stages, so it
/// visibly "steps" instead of sliding linearly. It only reaches 100% on the
/// very last stage, immediately before [onFinished] hands over to the app.
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
    required this.warmUp,
    required this.onFinished,
  });

  /// Real initialisation work that runs while the bar is filling.
  final Future<void> Function() warmUp;

  final VoidCallback onFinished;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  /// Milestone percentages with the pause that follows each of them.
  static const List<({int percent, int rampMs, int holdMs})> _stages =
      <({int percent, int rampMs, int holdMs})>[
    (percent: 14, rampMs: 420, holdMs: 150),
    (percent: 31, rampMs: 460, holdMs: 190),
    (percent: 48, rampMs: 420, holdMs: 170),
    (percent: 66, rampMs: 480, holdMs: 200),
    (percent: 83, rampMs: 460, holdMs: 210),
    (percent: 100, rampMs: 520, holdMs: 320),
  ];

  late final AnimationController _dots;
  Timer? _ticker;

  double _progress = 0;
  int _percent = 0;
  bool _handedOver = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Color(0xFF8ACB38),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _dots = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _run();
  }

  Future<void> _run() async {
    // Real work is capped so a slow device can never stall the bar; the whole
    // sequence stays comfortably under ten seconds.
    final warmUp = widget.warmUp().timeout(
          const Duration(seconds: 4),
          onTimeout: () {},
        );

    var from = 0.0;
    for (var i = 0; i < _stages.length; i++) {
      final stage = _stages[i];
      final to = stage.percent / 100;

      // The final stage waits for initialisation so 100% always means ready.
      if (i == _stages.length - 1) {
        await warmUp;
      }

      await _rampTo(from, to, Duration(milliseconds: stage.rampMs));
      if (!mounted) return;
      from = to;
      await Future<void>.delayed(Duration(milliseconds: stage.holdMs));
      if (!mounted) return;
    }

    if (!mounted || _handedOver) return;
    _handedOver = true;
    widget.onFinished();
  }

  Future<void> _rampTo(double from, double to, Duration duration) {
    final completer = Completer<void>();
    const frame = Duration(milliseconds: 16);
    final steps = (duration.inMilliseconds / frame.inMilliseconds).ceil();
    var step = 0;

    _ticker?.cancel();
    _ticker = Timer.periodic(frame, (timer) {
      if (!mounted) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      step++;
      final t = (step / steps).clamp(0.0, 1.0);
      final eased = Curves.easeInOutCubic.transform(t);
      final value = from + (to - from) * eased;
      setState(() {
        _progress = value;
        // Percent and bar are driven by the exact same number, so they can
        // never drift apart.
        _percent = (value * 100).round();
      });
      if (t >= 1) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
      }
    });

    return completer.future;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _dots.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFCBE86D),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            isLandscape
                ? AppAssets.loadingLandscape
                : AppAssets.loadingPortrait,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
          ),
          SafeArea(
            child: isLandscape ? _landscape(size) : _portrait(size),
          ),
        ],
      ),
    );
  }

  Widget _portrait(Size size) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: size.height * 0.12,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          _block(barWidth: size.width * 0.74, barHeight: 18, henSize: 46),
        ],
      ),
    );
  }

  Widget _landscape(Size size) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.md,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _block(
            barWidth: size.width * 0.34,
            barHeight: 12,
            henSize: 30,
            compact: true,
          ),
        ],
      ),
    );
  }

  Widget _block({
    required double barWidth,
    required double barHeight,
    required double henSize,
    bool compact = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _LoadingLabel(controller: _dots, compact: compact),
        SizedBox(height: compact ? 8 : 14),
        SizedBox(
          width: barWidth,
          child: _ProgressTrack(
            value: _progress,
            height: barHeight,
            henSize: henSize,
          ),
        ),
        SizedBox(height: compact ? 6 : 12),
        Text(
          '$_percent%',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: compact ? 16 : 22,
            fontWeight: FontWeight.w800,
            color: Brand.forest,
            letterSpacing: 0.4,
            shadows: const <Shadow>[
              Shadow(color: Color(0x40FFFFFF), blurRadius: 6, offset: Offset(0, 1)),
            ],
          ),
        ),
      ],
    );
  }
}

class _LoadingLabel extends StatelessWidget {
  const _LoadingLabel({required this.controller, required this.compact});

  final AnimationController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: compact ? 15 : 19,
      fontWeight: FontWeight.w700,
      color: Brand.forest,
      letterSpacing: 0.6,
      shadows: const <Shadow>[
        Shadow(color: Color(0x40FFFFFF), blurRadius: 6, offset: Offset(0, 1)),
      ],
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final dots = 1 + (controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text('Loading', style: style),
            SizedBox(
              width: compact ? 18 : 24,
              child: Text('.' * dots, style: style),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.value,
    required this.height,
    required this.henSize,
  });

  final double value;
  final double height;
  final double henSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= 0) return SizedBox(height: height + henSize * 0.62);
        final filled = (width * value).clamp(0.0, width);

        // clamp upper bounds to be always >= 0 so clamp() never throws.
        final innerWidth = (width - 4).clamp(0.0, double.infinity);
        final filledInner = (filled - 4).clamp(0.0, innerWidth);
        final henLeft = (filled - henSize * 0.5).clamp(
          0.0,
          (width - henSize).clamp(0.0, double.infinity),
        );

        return SizedBox(
          height: height + henSize * 0.62,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomLeft,
            children: <Widget>[
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    border: Border.all(
                      color: Brand.forest.withValues(alpha: 0.55),
                      width: 1.6,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1A0E4429),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 2,
                bottom: 2,
                child: Container(
                  height: (height - 4).clamp(0.0, double.infinity),
                  width: filledInner,
                  decoration: filledInner > 0
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                          gradient: const LinearGradient(
                            colors: <Color>[Brand.lime, Brand.moss, Brand.forest],
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                left: henLeft,
                bottom: height - 6,
                child: Image.asset(
                  AppAssets.henRunner,
                  width: henSize,
                  height: henSize,
                  filterQuality: FilterQuality.medium,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
