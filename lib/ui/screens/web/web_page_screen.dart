import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_config.dart';
import '../../../core/constants/offline_pages.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';

/// Renders the published Privacy Policy / Support pages.
///
/// The app works without a connection, so the screen never dead-ends: if the
/// live page cannot load, the bundled copy of the very same document is shown
/// instead. Either way the content is black text on a white background.
class WebPageScreen extends StatefulWidget {
  const WebPageScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<WebPageScreen> createState() => _WebPageScreenState();
}

class _WebPageScreenState extends State<WebPageScreen> {
  static const String _readabilityCss = '''
    (function () {
      var style = document.createElement('style');
      style.innerHTML =
        'html,body{background:#ffffff !important;color:#000000 !important;}' +
        'body{-webkit-text-size-adjust:100%;padding:14px 16px 40px !important;' +
        'font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;line-height:1.6;}' +
        'h1,h2,h3,h4,h5,h6,p,li,span,div,td,th,label,strong,em,b{color:#000000 !important;}' +
        'a{color:#0e4429 !important;}' +
        'input,textarea,select{background:#ffffff !important;color:#000000 !important;' +
        'border:1px solid #cccccc !important;border-radius:10px !important;' +
        'padding:10px 12px !important;font-size:16px !important;width:100% !important;' +
        'box-sizing:border-box !important;margin:6px 0 12px !important;}' +
        'button,input[type=submit]{background:#0e4429 !important;color:#ffffff !important;' +
        'border:none !important;border-radius:10px !important;padding:12px 18px !important;' +
        'font-size:16px !important;font-weight:600 !important;width:100% !important;}' +
        'img{max-width:100% !important;height:auto !important;}' +
        '*{max-width:100% !important;box-sizing:border-box;}';
      document.head.appendChild(style);
    })();
  ''';

  late final WebViewController _controller;
  bool _loading = true;
  bool _offlineFallback = false;
  Timer? _watchdog;

  bool get _isPrivacy => widget.url == AppConfig.privacyPolicyUrl;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) async {
            _watchdog?.cancel();
            await _controller.runJavaScript(_readabilityCss);
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            _loadOffline();
          },
          onHttpError: (_) => _loadOffline(),
        ),
      );
    _loadLive();
  }

  void _loadLive() {
    setState(() {
      _loading = true;
      _offlineFallback = false;
    });
    _watchdog?.cancel();
    // If the network hangs rather than failing outright, fall back anyway.
    _watchdog = Timer(const Duration(seconds: 8), _loadOffline);
    _controller.loadRequest(Uri.parse(widget.url));
  }

  void _loadOffline() {
    if (!mounted || _offlineFallback) return;
    _watchdog?.cancel();
    setState(() {
      _offlineFallback = true;
      _loading = true;
    });
    _controller.loadHtmlString(
      _isPrivacy ? OfflinePages.privacyPolicy : OfflinePages.support,
      baseUrl: widget.url,
    );
  }

  @override
  void dispose() {
    _watchdog?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF102117),
        title: Text(
          widget.title,
          style: context.text.titleLarge?.copyWith(
            color: const Color(0xFF102117),
          ),
        ),
        actions: <Widget>[
          IconButton(
            tooltip: 'Reload',
            onPressed: _loadLive,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            if (_offlineFallback && !_loading)
              Container(
                width: double.infinity,
                color: const Color(0xFFF4F7EF),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.offline_bolt_rounded,
                      size: 18,
                      color: Brand.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Showing the offline copy included with the app.',
                        style: context.text.bodySmall?.copyWith(
                          color: const Color(0xFF102117),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Stack(
                children: <Widget>[
                  WebViewWidget(controller: _controller),
                  if (_loading)
                    Container(
                      color: Colors.white,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.6,
                              color: c.accent,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Opening ${widget.title}…',
                            style: context.text.bodySmall?.copyWith(
                              color: const Color(0xFF4A5A4E),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
