import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Reads the cold-start push destination that SceneDelegate wrote to
/// UserDefaults (the `flutter.` prefix bridges UserDefaults ↔ SharedPreferences).
/// The value is one-shot: read once, then cleared.
///
/// ⚠️ [_dartKey] MUST stay in sync with SceneDelegate.launchRouteKey
/// (`flutter.chr_tap_trail`).
class ColdTapReader {
  static const String _dartKey = 'chr_tap_trail';

  static Future<String?> consume() async {
    if (!Platform.isIOS) return null;
    try {
      final preferences = await SharedPreferences.getInstance();
      final value = preferences.getString(_dartKey)?.trim();
      if (value == null || value.isEmpty) return null;
      await preferences.remove(_dartKey);
      return value;
    } catch (_) {
      return null;
    }
  }
}
