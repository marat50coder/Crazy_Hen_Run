import 'package:flutter/material.dart';

import '../../../foundation/constants/app_meta.dart';
import '../../../foundation/constants/embedded_docs.dart';
import '../../../foundation/services/external_links.dart';
import '../../../foundation/theme/henyard_theme.dart';
import '../../../foundation/theme/palette.dart';
import '../../widgets/surfaces.dart';

/// Native reader for the Privacy Policy and Support pages.
///
/// The full text is bundled with the binary. Optional actions open Mail or
/// Safari — never an in-app WebView.
class LegalDocScreen extends StatelessWidget {
  const LegalDocScreen({super.key, required this.document});

  const LegalDocScreen.privacy({super.key}) : document = EmbeddedDocs.privacy;

  const LegalDocScreen.support({super.key}) : document = EmbeddedDocs.support;

  final LegalDocument document;

  Future<void> _openWebsite(BuildContext context) async {
    final url = document.webUrl;
    if (url == null) return;
    final ok = await ExternalLinks.openWebsite(url);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Safari')),
    );
  }

  Future<void> _mail(BuildContext context) async {
    final address = document.email ?? AppMeta.supportEmail;
    final ok = await ExternalLinks.composeEmail(
      address,
      subject: '${AppMeta.appName} ${document.title}',
    );
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Write to $address from any mail app')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Insets.md,
          0,
          Insets.md,
          Insets.xxl,
        ),
        children: <Widget>[
          SoftCard(
            color: c.accentSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(document.title, style: context.text.headlineSmall),
                const SizedBox(height: 4),
                Text(
                  document.effective,
                  style: context.text.labelSmall,
                ),
                const SizedBox(height: Insets.sm),
                Text(
                  document.intro,
                  style: context.text.bodyLarge?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Insets.md),
          if (document.email != null || document.webUrl != null) ...<Widget>[
            Row(
              children: <Widget>[
                if (document.email != null)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _mail(context),
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      label: const Text('Email'),
                    ),
                  ),
                if (document.email != null && document.webUrl != null)
                  const SizedBox(width: Insets.sm),
                if (document.webUrl != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openWebsite(context),
                      icon: const Icon(Icons.open_in_browser_rounded, size: 18),
                      label: const Text('Safari'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),
          ],
          for (final section in document.sections) ...<Widget>[
            SectionHeader(title: section.heading),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (var i = 0; i < section.paragraphs.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(height: Insets.sm),
                    Text(section.paragraphs[i], style: context.text.bodyMedium),
                  ],
                  if (section.bullets.isNotEmpty) ...<Widget>[
                    if (section.paragraphs.isNotEmpty)
                      const SizedBox(height: Insets.sm),
                    for (final bullet in section.bullets)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('•  ', style: context.text.bodyMedium),
                            Expanded(
                              child: Text(
                                bullet,
                                style: context.text.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: Insets.md),
          ],
          Text(
            'This text ships with ${AppMeta.appName} ${AppMeta.version}. '
            'It is always available without a network connection.',
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}
