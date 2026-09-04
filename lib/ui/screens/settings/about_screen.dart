import 'package:flutter/material.dart';

import '../../../foundation/constants/artwork.dart';
import '../../../foundation/constants/app_meta.dart';
import '../../../foundation/theme/palette.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';
import '../legal/legal_doc_screen.dart';

/// Editorial layout: a centred logo, a short manifesto and a spec table.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.lg,
          0,
          Insets.lg,
          Insets.xxl,
        ),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                Image.asset(Artwork.logo, height: 96),
                const SizedBox(height: Insets.sm),
                Text(
                  'Version ${AppMeta.version}',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.xl),
          Text(
            'A habit tracker that actually goes somewhere.',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: Insets.sm),
          Text(
            'Most trackers give you a checkbox and hope you feel something. '
            'Crazy Hen Run turns every completed habit into distance on a track, '
            'and the hen in your pocket levels up as that distance grows. '
            'Streaks, categories, journals and charts are all there — but the '
            'point is simple: keep moving forward.',
            style: context.text.bodyLarge?.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: Insets.lg),
          SoftCard(
            color: c.accentSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const HenFigure(asset: Artwork.henLegend, size: 72),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('On-device first', style: context.text.titleSmall),
                      const SizedBox(height: 4),
                      Text(
                        'No account, no sync, no ads. Habits, logs, journal '
                        'entries and your profile photo stay on this device. '
                        'AppsFlyer measures installs and usage only.',
                        style: context.text.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          SectionHeader(title: 'Details'),
          SoftCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                _Row(label: 'App name', value: AppMeta.appName),
                _Row(label: 'Version', value: AppMeta.version),
                _Row(label: 'Bundle ID', value: AppMeta.bundleId),
                _Row(label: 'App ID', value: AppMeta.appId, last: true),
              ],
            ),
          ),
          const SizedBox(height: Insets.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalDocScreen.privacy(),
                    ),
                  ),
                  icon: const Icon(Icons.privacy_tip_rounded, size: 18),
                  label: const Text('Privacy'),
                ),
              ),
              const SizedBox(width: Insets.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LegalDocScreen.support(),
                    ),
                  ),
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text('Support'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Insets.lg),
          Center(
            child: Text(
              '© ${DateTime.now().year} Crazy Hen Run',
              style: context.text.labelSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Insets.md,
            vertical: 14,
          ),
          child: Row(
            children: <Widget>[
              Expanded(child: Text(label, style: context.text.bodyMedium)),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: context.text.titleSmall,
                ),
              ),
            ],
          ),
        ),
        if (!last)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Insets.md),
            child: Divider(height: 1, color: c.outline),
          ),
      ],
    );
  }
}
