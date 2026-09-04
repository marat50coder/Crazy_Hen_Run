import 'package:url_launcher/url_launcher.dart';

/// Opens the system browser or the Mail composer.
///
/// Legal pages must leave the process (Safari / Chrome), never load inside
/// an in-app WebView that could later swap content.
class ExternalLinks {
  const ExternalLinks._();

  static Future<bool> openWebsite(String url) {
    return launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<bool> composeEmail(String address, {String? subject}) {
    final uri = Uri(
      scheme: 'mailto',
      path: address,
      queryParameters: subject == null
          ? null
          : <String, String>{'subject': subject},
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
