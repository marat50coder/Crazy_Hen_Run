class AppConfig {
  const AppConfig._();

  static const String appName = 'Crazy Hen Run';
  static const String bundleId = 'com.crazyhenrun.crazyhenrungame';
  static const String appId = '6790464294';
  static const String version = '1.0.0';

  static const String privacyPolicyUrl =
      'https://crazyhennrun.com/privacy-policy.html';
  static const String supportUrl = 'https://crazyhennrun.com/support.html';

  /// Metres of "track" credited for a single completed habit.
  static const int metresPerCompletion = 250;

  /// Extra metres granted for every day of an active streak, capped below.
  static const int metresPerStreakDay = 15;
  static const int maxStreakBonusDays = 30;
}
