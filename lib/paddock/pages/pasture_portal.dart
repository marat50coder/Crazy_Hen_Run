import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../infra/coop_vault.dart';
import '../infra/pulse_hub.dart';
import '../infra/reach_scout.dart';
import '../infra/stride_client.dart';
import 'no_signal_page.dart';

/// Full-screen WebView shell (gray mode). Loads the config URL, applies the
/// native-feel JS injections, respects the safe area on all sides, recovers
/// from redirect loops / transient offline, and forwards push destinations.
class PasturePortal extends StatefulWidget {
  const PasturePortal({
    super.key,
    required this.url,
    required this.vault,
    required this.scout,
    required this.pulse,
    required this.client,
    this.coldLaunch = false,
  });

  final String url;
  final CoopVault vault;
  final ReachScout scout;
  final PulseHub pulse;
  final StrideClient client;
  final bool coldLaunch;

  @override
  State<PasturePortal> createState() => _PasturePortalState();
}

class _PasturePortalState extends State<PasturePortal>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  StreamSubscription<List<ConnectivityResult>>? _networkSubscription;
  bool _viewportReady = false;
  bool _coldReloadIssued = false;
  bool _offlineShown = false;
  int _redirectAttempts = 0;
  String? _lastMainUrl;
  Timer? _metricsDebounce;
  Size? _lastMetricsSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterImmersive();
    SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final params = Platform.isIOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _controller = WebViewController.fromPlatformCreationParams(
      params,
      onPermissionRequest: (request) => request.grant(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setUserAgent(widget.client.userAgent)
      ..enableZoom(false)
      ..setNavigationDelegate(_navigation());
    if (_controller.platform is WebKitWebViewController) {
      (_controller.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }

    widget.pulse.onDestination = (url) {
      final uri = Uri.tryParse(url);
      if (mounted && uri != null && uri.hasScheme) {
        _controller.loadRequest(uri);
      }
    };
    _networkSubscription = widget.scout.changes.listen((states) {
      if (states.every((state) => state == ConnectivityResult.none)) {
        // Connectivity is definitively gone — show offline immediately (no
        // DNS probe, which would hang and let the WebView render its own
        // error page first).
        _goOffline();
      }
    });

    if (widget.coldLaunch) {
      _settleColdViewport();
    } else {
      _viewportReady = true;
      _controller.loadRequest(Uri.parse(widget.url));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumePending());
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _settleColdViewport() async {
    _enterImmersive();
    // Let immersive mode settle in the phone's ACTUAL orientation before the
    // WebView mounts (no forced landscape nudge — that made the link open
    // sideways then flip). Any residual stretch is fixed by the post-load
    // resize + single reload in the current orientation.
    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    setState(() => _viewportReady = true);
    await _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    setState(() {});
    final view = View.of(context);
    final size = view.physicalSize;
    final rotated = _lastMetricsSize != null &&
        ((_lastMetricsSize!.width < _lastMetricsSize!.height) !=
            (size.width < size.height));
    _lastMetricsSize = size;
    if (!rotated) return;
    _enterImmersive();
    _metricsDebounce?.cancel();
    _pokeReflow(const <int>[40, 160, 320, 560, 850]);
  }

  void _pokeReflow(List<int> delaysMs) {
    for (final ms in delaysMs) {
      Timer(Duration(milliseconds: ms), () {
        if (!mounted) return;
        _controller.runJavaScript(
          'window.dispatchEvent(new Event("orientationchange"));'
          'window.dispatchEvent(new Event("resize"));'
          'if(window.visualViewport)'
          '  window.visualViewport.dispatchEvent(new Event("resize"));',
        ).catchError((_) {});
      });
    }
    _metricsDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!mounted) return;
      _applyInsetGuard();
      _applyZoomLock();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterImmersive();
      _consumePending();
    }
  }

  Future<void> _consumePending() async {
    final value = await widget.vault.consumePushUrl();
    final uri = value == null ? null : Uri.tryParse(value);
    if (mounted && uri != null && uri.hasScheme) {
      await _controller.loadRequest(uri);
    }
  }

  NavigationDelegate _navigation() {
    return NavigationDelegate(
      onPageStarted: (url) {
        _lastMainUrl = url;
      },
      onPageFinished: (_) {
        _redirectAttempts = 0;
        _applyInsetGuard();
        _applyZoomLock();
        _applyTapPolish();
        _applyKeyboardLift();
        _applyFocusScaleGuard();
        _applyInlinePlayback();
        Future<void>.delayed(const Duration(milliseconds: 800), () async {
          if (!mounted) return;
          setState(() {});
          await _controller.runJavaScript(
            'window.dispatchEvent(new Event("resize"));'
            'window.visualViewport?.dispatchEvent(new Event("resize"));',
          );
          _applyInsetGuard();
          if (widget.coldLaunch && !_coldReloadIssued) {
            _coldReloadIssued = true;
            await _controller.reload();
          }
        });
      },
      onWebResourceError: (error) {
        // -999 = cancelled (a new navigation superseded this one).
        if (error.errorCode == -999) return;
        // WKWebView sometimes reports isForMainFrame as null for the main
        // navigation — treat null as main-frame so a real load failure is
        // never silently swallowed (that leaves the app "frozen").
        final mainFrame = error.isForMainFrame ?? true;
        final lower = error.description.toLowerCase();
        final redirectLoop = error.errorCode == -1007 ||
            lower.contains('too_many_redirects') ||
            lower.contains('too many redirects');
        if (redirectLoop && _lastMainUrl != null && _redirectAttempts < 3) {
          _redirectAttempts++;
          _controller.loadRequest(Uri.parse(_lastMainUrl!));
          return;
        }
        if (!mainFrame) return;
        _showOfflineAfterProbe();
      },
      onNavigationRequest: (request) {
        final uri = Uri.tryParse(request.url);
        if (uri == null) return NavigationDecision.prevent;
        if (<String>{'http', 'https', 'about', 'data', 'blob'}
            .contains(uri.scheme)) {
          if (request.isMainFrame) _lastMainUrl = request.url;
          return NavigationDecision.navigate;
        }
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return NavigationDecision.prevent;
      },
    );
  }

  /// Confirms the outage with a reachability probe (WebView load errors can be
  /// transient) before routing to the offline screen.
  Future<void> _showOfflineAfterProbe() async {
    if (_offlineShown) return;
    bool online = true;
    try {
      online = await widget.scout.canReachNetwork();
    } catch (_) {
      online = false;
    }
    if (online) return;
    _goOffline();
  }

  Future<void> _goOffline() async {
    if (_offlineShown || !mounted) return;
    _offlineShown = true;
    String current;
    try {
      current = await _controller.currentUrl() ?? widget.url;
    } catch (_) {
      current = widget.url;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => NoSignalPage(
          scout: widget.scout,
          retryBuilder: (_) => PasturePortal(
            url: current,
            vault: widget.vault,
            scout: widget.scout,
            pulse: widget.pulse,
            client: widget.client,
          ),
        ),
      ),
    );
  }

  /// Neutralises the site's safe-area CSS variables and locks document edges
  /// against rubber-band overscroll. Never zeroes html/body padding (that
  /// would squash the partner site's own gutters).
  void _applyInsetGuard() {
    _controller.runJavaScript(r'''
(() => {
  const scope = window;
  if (scope.__chrEdgeFix) return;
  scope.__chrEdgeFix = true;
  const tag = 'chr-edge-sheet';
  const css = [
    ':root{',
    '--safe-area-inset-top:0px!important;',
    '--safe-area-inset-right:0px!important;',
    '--safe-area-inset-bottom:0px!important;',
    '--safe-area-inset-left:0px!important;',
    '--sat:0px!important;--sar:0px!important;',
    '--sab:0px!important;--sal:0px!important;',
    '--safe-top:0px!important;--safe-right:0px!important;',
    '--safe-bottom:0px!important;--safe-left:0px!important;',
    '}',
    'html,body{overscroll-behavior:none!important;',
    'overscroll-behavior-y:none!important;}'
  ].join('');
  const kbUp = () => {
    const vv = scope.visualViewport;
    return !!vv && vv.height < scope.innerHeight * 0.75;
  };
  const paint = () => {
    if (kbUp()) return;
    const head = document.head || document.documentElement;
    if (!head) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.name = 'viewport';
      meta.content = 'width=device-width, initial-scale=1, viewport-fit=contain';
      head.appendChild(meta);
    } else {
      const trimmed = (meta.content || '')
        .replace(/,?\s*viewport-fit\s*=\s*\w+/ig, '').trim();
      meta.content = `${trimmed}${trimmed ? ', ' : ''}viewport-fit=contain`;
    }
    let sheet = document.getElementById(tag);
    if (!sheet) {
      sheet = document.createElement('style');
      sheet.id = tag;
      head.appendChild(sheet);
    }
    sheet.textContent = css;
  };
  const queue = () => { scope.setTimeout(paint, 170); scope.setTimeout(paint, 640); };
  ['pushState', 'replaceState'].forEach((fn) => {
    const orig = history[fn];
    history[fn] = function(...rest) {
      const out = orig.apply(this, rest);
      queue();
      return out;
    };
  });
  scope.addEventListener('popstate', queue);
  paint();
  scope.setInterval(paint, 2900);
})();
''');
  }

  /// Locks the page at 1:1 scale (no pinch / double-tap / gesture zoom).
  void _applyZoomLock() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__chrScaleLock) return;
  window.__chrScaleLock = true;
  const setMeta = () => {
    const head = document.head || document.documentElement;
    if (!head) return;
    let meta = document.querySelector('meta[name="viewport"]');
    if (!meta) {
      meta = document.createElement('meta');
      meta.setAttribute('name', 'viewport');
      head.appendChild(meta);
    }
    meta.setAttribute('content',
      'width=device-width, initial-scale=1.0, maximum-scale=1.0, ' +
      'minimum-scale=1.0, user-scalable=no, viewport-fit=contain');
  };
  setMeta();
  const block = (ev) => { ev.preventDefault(); };
  ['gesturestart', 'gesturechange', 'gestureend'].forEach((t) =>
    document.addEventListener(t, block, {passive: false}));
  document.addEventListener('touchmove', (ev) => {
    if (ev.scale !== undefined && ev.scale !== 1) ev.preventDefault();
  }, {passive: false});
  let prevTap = 0;
  document.addEventListener('touchend', (ev) => {
    const at = Date.now();
    if (at - prevTap <= 300) ev.preventDefault();
    prevTap = at;
  }, {passive: false});
  ['pushState', 'replaceState'].forEach((fn) => {
    const orig = history[fn];
    history[fn] = function(...rest) {
      const out = orig.apply(this, rest);
      setTimeout(setMeta, 150);
      return out;
    };
  });
  window.addEventListener('popstate', () => setTimeout(setMeta, 150));
})();
''');
  }

  /// Removes the grey tap-highlight box + long-press callout so tapping feels
  /// native. Inputs stay selectable.
  void _applyTapPolish() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__chrTapClean) return;
  window.__chrTapClean = true;
  const style = document.createElement('style');
  style.id = 'chr-tap-clean';
  style.textContent =
    '*{-webkit-tap-highlight-color:transparent!important;}' +
    '*:not(input):not(textarea):not([contenteditable="true"]){' +
      '-webkit-touch-callout:none!important;}';
  (document.head || document.documentElement).appendChild(style);
})();
''');
  }

  void _applyKeyboardLift() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__chrInputRaise) return;
  window.__chrInputRaise = true;
  const editable = (node) => !!node && (
    node.matches?.('input, textarea, select, [contenteditable="true"]')
  );
  const reveal = () => {
    const active = document.activeElement;
    if (!editable(active)) return;
    active.scrollIntoView({behavior: 'auto', block: 'nearest'});
  };
  document.addEventListener('focusin', (ev) => {
    if (editable(ev.target)) window.setTimeout(reveal, 350);
  }, true);
})();
''');
  }

  void _applyFocusScaleGuard() {
    if (!Platform.isIOS) return;
    _controller.runJavaScript(r'''
(() => {
  if (window.__chrFocusScale) return;
  window.__chrFocusScale = true;
  const style = document.createElement('style');
  style.textContent =
    'input,textarea,select,[contenteditable="true"]{' +
    'font-size:max(16px,1em)!important;}';
  (document.head || document.documentElement).appendChild(style);
})();
''');
  }

  void _applyInlinePlayback() {
    _controller.runJavaScript(r'''
(() => {
  if (window.__chrInlinePlay) return;
  window.__chrInlinePlay = true;
  const wake = (video) => {
    if (!(video instanceof HTMLVideoElement)) return;
    video.setAttribute('playsinline', '');
    video.setAttribute('webkit-playsinline', '');
    video.playsInline = true;
    video.autoplay = true;
    const p = video.play();
    if (p?.catch) p.catch(() => {});
  };
  const sweep = (node) => {
    if (node instanceof HTMLVideoElement) wake(node);
    node.querySelectorAll?.('video').forEach(wake);
  };
  sweep(document);
  new MutationObserver((records) => {
    records.forEach((record) => record.addedNodes.forEach(sweep));
  }).observe(document.documentElement, {childList: true, subtree: true});
})();
''');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _metricsDebounce?.cancel();
    _networkSubscription?.cancel();
    widget.pulse.onDestination = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: _viewportReady
            ? Padding(
                // Respect the notch/Dynamic Island (top + sides) AND the home
                // indicator (bottom) in both orientations. Cold-start uses
                // viewPadding (never EdgeInsets.zero) so the bottom inset is
                // not lost while immersive mode settles.
                padding: EdgeInsets.only(
                  top: safe.top,
                  bottom: safe.bottom,
                  left: safe.left,
                  right: safe.right,
                ),
                child: WebViewWidget(controller: _controller),
              )
            : const ColoredBox(color: Colors.black),
      ),
    );
  }
}
