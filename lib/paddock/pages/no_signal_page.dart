import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../infra/reach_scout.dart';

/// Offline screen. Retry re-runs the whole pipeline by pushing a fresh
/// [retryBuilder] widget with THIS page's own mounted context (never a
/// captured parent context, which is defunct after pushReplacement).
class NoSignalPage extends StatefulWidget {
  const NoSignalPage({
    super.key,
    required this.scout,
    required this.retryBuilder,
  });

  final ReachScout scout;
  final WidgetBuilder retryBuilder;

  @override
  State<NoSignalPage> createState() => _NoSignalPageState();
}

class _NoSignalPageState extends State<NoSignalPage> {
  bool _checking = false;
  bool _stillOffline = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // Allow landscape so the artwork rotates (the boot gate locks portrait
    // right before routing here).
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  Future<void> _retry() async {
    if (_checking) return;
    HapticFeedback.lightImpact();
    setState(() {
      _checking = true;
      _stillOffline = false;
    });
    bool online = false;
    try {
      online = await widget.scout.canReachNetwork();
    } catch (_) {
      online = false;
    }
    if (!mounted) return;
    if (online) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: widget.retryBuilder),
      );
      return;
    }
    setState(() {
      _checking = false;
      _stillOffline = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final landscape = media.orientation == Orientation.landscape;
    final background = landscape
        ? 'assets/Horizontal_Nowifi_Screen.webp'
        : 'assets/Vertical_Nowifi_Screen.webp';
    final width = landscape
        ? (media.size.width * 0.40).clamp(300.0, 520.0)
        : (media.size.width * 0.66).clamp(260.0, 420.0);
    final height = landscape ? 70.0 : 74.0;
    final align =
        landscape ? const Alignment(0, 0.82) : const Alignment(0, 0.80);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Image.asset(
            background,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
          ),
          Align(
            alignment: align,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                _RetryButton(
                  width: width,
                  height: height,
                  busy: _checking,
                  onTap: _retry,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  child: _stillOffline
                      ? const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                            'No connection yet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              shadows: <Shadow>[
                                Shadow(color: Colors.black, blurRadius: 5),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RetryButton extends StatelessWidget {
  const _RetryButton({
    required this.width,
    required this.height,
    required this.busy,
    required this.onTap,
  });

  final double width;
  final double height;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF6FD26B), Color(0xFF1F8E4A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0xFF07351F), width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(34),
            onTap: busy ? null : onTap,
            child: Center(
              child: busy
                  ? const SizedBox.square(
                      dimension: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.8,
                        color: Color(0xFF06301B),
                      ),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF06301B),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Retry',
                          style: TextStyle(
                            color: Color(0xFF06301B),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
