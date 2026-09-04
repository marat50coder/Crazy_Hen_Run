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

  /// User-facing product name. Used on the home screen, permission sheets,
  /// notifications, the share card, and the store listing.
  static const String appName = 'Crazy Hen Run';

  /// One-line product definition. Matches the App Store subtitle limit.
  static const String storeSubtitle = 'Habits that turn into miles';

  /// iOS/Android bundle identifier. Must match the store record.
  static const String bundleId = 'com.crazyhenrun.crazyhenrungame';

  /// Numeric App Store record id, used for deep-linking review pages.
  static const String appId = '6790464294';

  /// Marketing version. Matches `pubspec.yaml` and both native manifests.
  static const String version = '1.0.3';

  // ── Legal / support ──────────────────────────────────────────────────

  /// Public Privacy Policy URL. Opened in Safari, never inside a WebView.
  static const String privacyPolicyUrl =
      'https://crazyhennrun.com/privacy-policy.html';

  /// Public Support URL. Opened in Safari, never inside a WebView.
  static const String supportUrl = 'https://crazyhennrun.com/support.html';

  static const String supportEmail = 'support@crazyhennrun.com';

  /// AppsFlyer Dev Key. Used only for install and usage measurement.
  static const String appsFlyerDevKey = 'HxiGyKQNpvWDytNED5fKaP';

  // ── Store listing copy ───────────────────────────────────────────────
  // Paste these into App Store Connect so the listing describes the same
  // habit + run companion that ships in the binary.

  static const String storePromotionalText =
      'Close habits, cover distance. A hen companion that levels up as you keep streaks and go for a run.';

  static const String storeDescription = '''
Crazy Hen Run is a habit tracker that turns daily routines into distance on a track. Close a habit, earn metres, and watch the hen in your pocket level up as the distance grows.

What you can do
• Add habits, streaks and a daily checklist
• Log a run or walk with the on-device motion sensor — no GPS
• Build interval workouts and weekly challenges
• Keep a journal, calendar and weekly stats
• Level the hen from Chick to Legend as you stay consistent

There is no account, no cloud sync and no ads. Habits, logs, journal entries and your profile photo stay on this device. Installs and anonymous usage are measured with AppsFlyer.

This is a fitness and habit companion, not an endless runner.
''';

  static const List<String> storeScreenshotCaptions = <String>[
    'Today — close habits, cover distance',
    'Run — timed sessions and intervals, no GPS',
    'Habits — streaks, archive and weekly sprint',
    'Stats — the week at a glance',
    'Profile — hen rank, achievements and on-device data',
  ];

  /// Paste into App Store Connect → this version → App Review Information.
  static const String reviewNotes = '''
Crazy Hen Run is a habit tracker and running companion, not an endless-runner game.

How to review
• No account and no login. Open the app and complete the short onboarding (or Skip).
• Today opens first with three starter habits (Morning run, Drink water, Read 10 pages). Drink water starts at 2 of 8 so the list is not empty.
• Close a habit on Today — that adds metres to the hen's track.
• Run tab: start a Free run, wait a few seconds, finish it. Distance uses the motion sensor / step estimate. No GPS and no location permission.
• Stats, Coop and You are populated from those local habits and runs.
• Settings → Privacy Policy and Support are native screens. Safari is only used if the reviewer taps the optional Safari button.

Privacy
• Habits, journal text and the profile photo stay on device.
• AppsFlyer is used only for install and anonymous usage events. Advertising identifiers (IDFA) are disabled. There is no ATT prompt. There is no in-app WebView and no remote switch that changes the UI.

This binary is the product we intend to keep on the store.
''';

  static const String whatsNew =
      'Starter habits on first launch, clearer habit + run framing, and an on-device privacy policy that names AppsFlyer.';

  // ── Gameplay tuning ──────────────────────────────────────────────────

  /// Metres of "track" credited each time a habit is fully completed.
  static const int metresPerCompletion = 250;

  /// Additional metres granted for every day of an active streak.
  static const int metresPerStreakDay = 15;

  /// The streak bonus stops growing after this many days.
  static const int maxStreakBonusDays = 30;
}
