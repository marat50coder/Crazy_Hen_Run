/// Static, compile-time constants that describe the shipping build.
///
/// This is the single source of truth for anything a screen needs to know
/// about the app itself (its display name, its store identity, the URLs of
/// the legal pages, and the tuning knobs for the "distance" reward system).
///
/// Everything is a `const` so it can be embedded straight into widget trees
/// without allocating.
class AppMeta {
  const AppMeta._();

  // ── Identity ─────────────────────────────────────────────────────────

  /// User-facing product name. Never change without also updating the App
  /// Store listing, launch icon captions, and support pages.
  static const String appName = 'Crazy Hen Run';

  /// iOS/Android bundle identifier. Must match the store record.
  static const String bundleId = 'com.crazyhenrun.crazyhenrungame';

  /// Numeric App Store record id, used for deep-linking review pages.
  static const String appId = '6790464294';

  /// Marketing version. Matches `pubspec.yaml` and both native manifests.
  static const String version = '1.0.2';

  // ── Legal / support pages ────────────────────────────────────────────

  /// Live Privacy Policy URL. A local copy is embedded for offline mode.
  static const String privacyPolicyUrl =
      'https://crazyhennrun.com/privacy-policy.html';

  /// Live Support URL. Also mirrored offline.
  static const String supportUrl = 'https://crazyhennrun.com/support.html';

  // ── Gameplay tuning ──────────────────────────────────────────────────

  /// Metres of "track" credited each time a habit is fully completed.
  static const int metresPerCompletion = 250;

  /// Additional metres granted for every day of an active streak.
  static const int metresPerStreakDay = 15;

  /// The streak bonus stops growing after this many days.
  static const int maxStreakBonusDays = 30;
}
