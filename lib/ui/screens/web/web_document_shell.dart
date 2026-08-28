import 'package:flutter/material.dart';

import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';

/// A thin light-green banner shown while the WebView is displaying the
/// bundled offline copy of a document.
class OfflineNoticeBar extends StatelessWidget {
  const OfflineNoticeBar({super.key});

  static const Color _stripe = Color(0xFFF4F7EF);
  static const Color _ink = Color(0xFF102117);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _stripe,
      padding: const EdgeInsets.symmetric(horizontal: Insets.md, vertical: 10),
      child: Row(
        children: <Widget>[
          const Icon(Icons.offline_bolt_rounded, size: 18, color: Meadow.forest),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing the offline copy included with the app.',
              style: context.text.bodySmall?.copyWith(color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-bleed white overlay that hides the WebView while it is still
/// painting, so users never see the raw white-to-content flash.
class WebViewLoadingOverlay extends StatelessWidget {
  const WebViewLoadingOverlay({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
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
              color: palette.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Opening $label…',
            style: context.text.bodySmall?.copyWith(
              color: const Color(0xFF4A5A4E),
            ),
          ),
        ],
      ),
    );
  }
}
