import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../foundation/constants/app_meta.dart';
import '../../../foundation/constants/embedded_docs.dart';
import '../../../foundation/theme/palette.dart';
import 'web_document_shell.dart';
import 'web_reader_style.dart';

/// Renders one of the two long-form documents that the app links out to –
/// the Privacy Policy or the Support page.
///
/// The philosophy of the screen is simple: **users must always be able to
/// read the document**. That means:
///
///  * We prefer the live version from the site so users get any updates.
///  * If the network is unreachable, times out, or the server responds with
///    an error, we transparently fall back to the copy bundled inside the
///    app (see [EmbeddedDocs]). No dead ends.
///  * The rendered document is normalised to a paper-and-ink reader
    ///    look via [buildReaderInkScript] so it stays legible even if the site
    ///    theme changes.
class WebDocScreen extends StatefulWidget {
  const WebDocScreen({
    super.key,
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  State<WebDocScreen> createState() => _WebDocScreenState();
}

class _WebDocScreenState extends State<WebDocScreen> {
  /// How long we let the live request run before giving up and switching to
  /// the bundled copy. A generous ceiling that still keeps the UX snappy.
  static const Duration _liveTimeout = Duration(milliseconds: 11200);

  static const Color _paperInk = Color(0xFF102117);

  late final WebViewController _controller;

  /// Whether the WebView is still rendering the current request.
  bool _isBusy = true;

  /// ``true`` once we've already loaded the bundled copy for this session.
  bool _showingOfflineCopy = false;

  Timer? _timeoutHandle;

  bool get _isPrivacyDocument => widget.url == AppMeta.privacyPolicyUrl;

  @override
  void initState() {
    super.initState();
    _controller = _buildController();
    _requestLiveDocument();
  }

  @override
  void dispose() {
    _timeoutHandle?.cancel();
    super.dispose();
  }

  // ── WebView wiring ────────────────────────────────────────────────────

  WebViewController _buildController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(_navigationDelegate());
  }

  NavigationDelegate _navigationDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {
        if (!mounted) return;
        setState(() => _isBusy = true);
      },
      onPageFinished: (_) => _handlePageFinished(),
      onWebResourceError: (error) {
        if (error.isForMainFrame == false) return;
        _fallbackToBundledCopy();
      },
      onHttpError: (_) => _fallbackToBundledCopy(),
    );
  }

  Future<void> _handlePageFinished() async {
    _timeoutHandle?.cancel();
    await _controller.runJavaScript(buildReaderInkScript());
    if (!mounted) return;
    setState(() => _isBusy = false);
  }

  // ── Public actions ────────────────────────────────────────────────────

  void _requestLiveDocument() {
    setState(() {
      _isBusy = true;
      _showingOfflineCopy = false;
    });
    _timeoutHandle?.cancel();
    // A silent network hang would leave the loader spinning forever, so we
    // pessimistically arm a watchdog before firing the request.
    _timeoutHandle = Timer(_liveTimeout, _fallbackToBundledCopy);
    _controller.loadRequest(Uri.parse(widget.url));
  }

  void _fallbackToBundledCopy() {
    if (!mounted || _showingOfflineCopy) return;
    _timeoutHandle?.cancel();
    setState(() {
      _showingOfflineCopy = true;
      _isBusy = true;
    });
    _controller.loadHtmlString(
      _isPrivacyDocument ? EmbeddedDocs.privacyPolicy : EmbeddedDocs.support,
      baseUrl: widget.url,
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SafeArea(top: false, child: _buildBody()),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      foregroundColor: _paperInk,
      title: Text(
        widget.title,
        style: context.text.titleLarge?.copyWith(color: _paperInk),
      ),
      actions: <Widget>[
        IconButton(
          tooltip: 'Reload',
          onPressed: _requestLiveDocument,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Column(
      children: <Widget>[
        if (_showingOfflineCopy && !_isBusy) const OfflineNoticeBar(),
        Expanded(
          child: Stack(
            children: <Widget>[
              WebViewWidget(controller: _controller),
              if (_isBusy) WebViewLoadingOverlay(label: widget.title),
            ],
          ),
        ),
      ],
    );
  }
}
