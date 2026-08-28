/// Bundled copies of the legal and support pages.
///
/// The app is fully offline, so these are shown whenever the live pages cannot
/// be reached. The content mirrors the published pages word for word.
class EmbeddedDocs {
  const EmbeddedDocs._();

  static const String _style = '''
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
      :root { color-scheme: light; }
      html, body {
        background: #ffffff !important;
        color: #000000 !important;
        margin: 0;
        padding: 0;
      }
      body {
        font-family: -apple-system, "Segoe UI", Roboto, Arial, sans-serif;
        line-height: 1.6;
        font-size: 16px;
        padding: 20px 18px 48px;
        -webkit-text-size-adjust: 100%;
      }
      h1 { font-size: 26px; margin: 0 0 6px; color: #000000; }
      h2 { font-size: 18px; margin: 26px 0 8px; color: #000000; }
      p, li { color: #000000; }
      ul { padding-left: 20px; }
      a { color: #0e4429; }
      .meta { color: #444444; font-size: 14px; margin-bottom: 22px; }
      .card {
        border: 1px solid #dddddd;
        border-radius: 14px;
        padding: 16px;
        margin-top: 18px;
      }
      .label { font-size: 13px; color: #444444; margin-bottom: 4px; }
      .value { font-size: 16px; font-weight: 600; color: #000000; }
      .note {
        background: #f4f7ef;
        border-radius: 14px;
        padding: 14px 16px;
        margin-top: 22px;
        font-size: 14px;
        color: #000000;
      }
    </style>
  ''';

  static const String privacyPolicy = '''
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Privacy Policy</title>$_style</head>
<body>
<h1>Privacy Policy</h1>
<p class="meta"><strong>Effective Date:</strong> June 2026</p>

<p>Developer ("we", "us", or "our") operates the <strong>Crazy Hen Run</strong> mobile application ("Service"). This Privacy Policy explains how information is collected, used, and protected when you use the Service.</p>

<h2>Information We Collect</h2>
<p>The Service may collect limited technical information necessary for operation and improvement of the application, including:</p>
<ul>
  <li>Device type and model</li>
  <li>Operating system version</li>
  <li>Anonymous usage statistics</li>
  <li>Diagnostic and crash information</li>
  <li>IP address (when required for security and analytics purposes)</li>
</ul>
<p>We do not intentionally collect sensitive personal information such as financial account details, government-issued identification numbers, or biometric data.</p>

<h2>How We Use Information</h2>
<ul>
  <li>Provide and maintain the Service</li>
  <li>Improve app functionality and user experience</li>
  <li>Monitor application performance and stability</li>
  <li>Detect, prevent, and resolve technical issues</li>
  <li>Comply with legal obligations</li>
</ul>

<h2>Data Storage and Security</h2>
<p>We take reasonable measures to protect information from unauthorized access, alteration, disclosure, or destruction. However, no method of electronic transmission or storage is completely secure.</p>

<h2>Third-Party Services</h2>
<p>The Service may use third-party providers for analytics, crash reporting, hosting, or other operational purposes. These providers may process information solely to provide services on our behalf.</p>

<h2>Data Retention</h2>
<p>We retain information only for as long as necessary to provide the Service, comply with legal obligations, resolve disputes, and enforce agreements.</p>

<h2>Data Deletion</h2>
<p>Users have the right to request deletion of their personal data. To request deletion of data associated with Crazy Hen Run, please contact us at:</p>
<p><strong>Email:</strong> <a href="mailto:support@crazyhennrun.com">support@crazyhennrun.com</a></p>
<p>When submitting a deletion request, please provide sufficient information to identify your account or device. Verified requests will be processed within a reasonable timeframe.</p>
<p>If the application stores data only on the user's device, users may permanently delete all stored data by uninstalling the application and clearing the application's local storage.</p>

<h2>Your Rights</h2>
<p>Depending on your location, you may have rights regarding access, correction, deletion, restriction, or portability of your personal data under applicable privacy laws, including the GDPR.</p>

<h2>Children's Privacy</h2>
<p>The Service is not intended for children under the age of 18, and we do not knowingly collect personal information from children.</p>

<h2>Changes to This Privacy Policy</h2>
<p>We may update this Privacy Policy from time to time. Changes become effective when posted on this page. Users are encouraged to review this policy periodically.</p>

<h2>Contact Us</h2>
<p>If you have questions about this Privacy Policy or wish to exercise your privacy rights, please contact:</p>
<p><strong>Developer:</strong> Crazy Hen Run<br>
<strong>Email:</strong> <a href="mailto:support@crazyhennrun.com">support@crazyhennrun.com</a></p>

<div class="note">You are reading the offline copy that ships with the app, so this policy is always available — even without an internet connection.</div>
</body></html>
''';

  static const String support = '''
<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8"><title>Support</title>$_style</head>
<body>
<h1>Support for Crazy Hen Run</h1>
<p class="meta">Questions, bug reports and feature requests are all welcome.</p>

<p>The support form needs an internet connection. While you are offline you can still reach us directly by email — write from any mail app and we will pick it up.</p>

<div class="card">
  <div class="label">Support email</div>
  <div class="value"><a href="mailto:support@crazyhennrun.com">support@crazyhennrun.com</a></div>
</div>

<div class="card">
  <div class="label">Support page</div>
  <div class="value"><a href="https://crazyhennrun.com/support.html">crazyhennrun.com/support.html</a></div>
</div>

<h2>What to include</h2>
<ul>
  <li>What you were doing when the problem appeared</li>
  <li>Your device model and Android version</li>
  <li>A screenshot, if the issue is visual</li>
</ul>

<h2>Your data</h2>
<p>Crazy Hen Run stores habits, streaks, journal entries and your profile photo on your device only. Uninstalling the app removes all of it.</p>

<div class="note">You are reading the offline copy that ships with the app. Reconnect and reopen this screen to use the online support form.</div>
</body></html>
''';
}
