import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../coop_marshal.dart';
import '../core/coop_models.dart';
import 'no_signal_page.dart';
import 'pasture_portal.dart';
import 'pulse_invite.dart';

/// Splash + routing point. Shows the loading artwork (orientation-aware) with
/// a progress bar while [CoopMarshal.decide] runs the attribution → config
/// pipeline, then routes to the WebView (gray) or the native game (organic).
class WarmupGate extends StatefulWidget {
  const WarmupGate({super.key, this.marshal});

  final CoopMarshal? marshal;

  @override
  State<WarmupGate> createState() => _WarmupGateState();
}

class _WarmupGateState extends State<WarmupGate> {
  double _progress = 0;
  CoopDest? _destination;
  bool _started = false;
  bool _navigating = false;
  late final DateTime _startTime;
  Timer? _hardDeadline;
  static const Duration _minSplash = Duration(milliseconds: 1600);

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _hardDeadline = Timer(const Duration(seconds: 8), () {
      if (mounted && !_navigating) {
        _destination ??= const NativeStop();
        _maybeNavigate();
      }
    });
  }

  @override
  void dispose() {
    _hardDeadline?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final marshal = widget.marshal;
    if (marshal == null) {
      _destination = const NativeStop();
      if (mounted) setState(() => _progress = 1);
      _maybeNavigate();
      return;
    }
    try {
      _destination = await marshal.decide(
        onProgress: (value) {
          if (mounted) setState(() => _progress = value.clamp(0.0, 1.0));
        },
      );
    } catch (_) {
      _destination = const NativeStop();
    }
    if (mounted) setState(() => _progress = 1);
    _hardDeadline?.cancel();
    _maybeNavigate();
  }

  Future<void> _maybeNavigate() async {
    if (_navigating || _destination == null) return;
    final elapsed = DateTime.now().difference(_startTime);
    if (elapsed < _minSplash) {
      await Future<void>.delayed(_minSplash - elapsed);
    }
    if (!mounted || _navigating) return;
    _navigating = true;
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    if (!mounted) return;
    await _open(_destination!);
  }

  Future<void> _open(CoopDest destination) async {
    final marshal = widget.marshal;

    // Organic / gate disabled → native game (its own MaterialApp + providers).
    if (destination is NativeStop || marshal == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const CrazyHenRunApp()),
      );
      return;
    }

    if (destination is OfflineStop) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => NoSignalPage(
            scout: marshal.scout,
            retryBuilder: (_) => WarmupGate(marshal: marshal),
          ),
        ),
      );
      return;
    }

    if (destination is PortalStop) {
      Widget portalBuilder(BuildContext _) => PasturePortal(
            url: destination.url,
            coldLaunch: destination.coldLaunch,
            vault: marshal.vault,
            scout: marshal.scout,
            pulse: marshal.pulse,
            client: marshal.client,
          );

      void openPortal() {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: portalBuilder),
        );
      }

      if (marshal.vault.shouldShowPushInvite &&
          await marshal.pulse.canOfferPermission()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => PulseInvite(
              vault: marshal.vault,
              pulse: marshal.pulse,
              nextBuilder: portalBuilder,
            ),
          ),
        );
      } else {
        openPortal();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final landscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final asset = landscape
        ? 'assets/loadingScreengorizontal.webp'
        : 'assets/loadingScreenvertical.webp';
    final screenW = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF02311D),
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            asset,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) =>
                const ColoredBox(color: Color(0xFF02311D)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: landscape ? 18 : 54),
                child: _WarmupBar(
                  progress: _progress,
                  width: landscape ? screenW * 0.42 : screenW * 0.74,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarmupBar extends StatelessWidget {
  const _WarmupBar({required this.progress, required this.width});

  final double progress;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF07351F), width: 2.5),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  builder: (context, value, _) {
                    return FractionallySizedBox(
                      widthFactor: value <= 0 ? 0.001 : value,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Color(0xFFFFC23C),
                              Color(0xFF7EE05B),
                              Color(0xFF1F8E4A),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const _WarmupLabel(),
      ],
    );
  }
}

class _WarmupLabel extends StatefulWidget {
  const _WarmupLabel();

  @override
  State<_WarmupLabel> createState() => _WarmupLabelState();
}

class _WarmupLabelState extends State<_WarmupLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final phase = (_ctrl.value * 3).floor() % 3;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.32),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Loading',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.6,
                  shadows: <Shadow>[
                    Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: i <= phase ? 1.0 : 0.3,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
