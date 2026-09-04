import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_meta.dart';

/// AppsFlyer install and usage measurement.
///
/// IDFA is not requested. Conversion and deep-link callbacks are not
/// registered, so this SDK cannot change what the app shows.
class HenAnalytics {
  HenAnalytics._();

  static final HenAnalytics instance = HenAnalytics._();

  AppsflyerSdk? _sdk;
  bool _ready = false;

  Future<void> prepare() async {
    if (_ready) return;
    try {
      final sdk = AppsflyerSdk(
        AppsFlyerOptions(
          afDevKey: AppMeta.appsFlyerDevKey,
          appId: AppMeta.appId,
          showDebug: kDebugMode,
          disableAdvertisingIdentifier: true,
        ),
      );
      await sdk.initSdk(
        registerConversionDataCallback: false,
        registerOnAppOpenAttributionCallback: false,
        registerOnDeepLinkingCallback: false,
      );
      _sdk = sdk;
      _ready = true;
    } catch (_) {
      // Measurement must never block launch.
    }
  }

  Future<void> log(String name, [Map<String, dynamic>? values]) async {
    final sdk = _sdk;
    if (!_ready || sdk == null) return;
    try {
      await sdk.logEvent(name, values);
    } catch (_) {}
  }
}
