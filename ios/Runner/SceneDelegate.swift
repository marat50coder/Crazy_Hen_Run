import Flutter
import UIKit
import UserNotifications

/// Captures a cold-start push tap (app killed) that iOS delivers through the
/// scene connection — NOT through Firebase's swizzled path. The destination URL
/// is written to UserDefaults where ColdTapReader (Dart) consumes it FIRST on
/// boot.
///
/// ⚠️ [launchRouteKey] MUST match ColdTapReader._dartKey (`chr_tap_trail`),
/// including the `flutter.` prefix that bridges UserDefaults ↔ SharedPreferences.
class SceneDelegate: FlutterSceneDelegate {
  static let launchRouteKey = "flutter.chr_tap_trail"

  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)

    guard
      let response = connectionOptions.notificationResponse,
      let destination = Self.destination(
        inside: response.notification.request.content.userInfo
      )
    else { return }

    let defaults = UserDefaults.standard
    defaults.set(destination, forKey: Self.launchRouteKey)
    defaults.synchronize()

    #if DEBUG
    NSLog("[CHR.ROUTE] captured notification destination")
    #endif
  }

  private static func destination(
    inside payload: [AnyHashable: Any]
  ) -> String? {
    let candidates = ["deep_link", "target", "url", "deeplink", "link"]

    func firstValue(in dictionary: [AnyHashable: Any]) -> String? {
      for candidate in candidates {
        guard let value = dictionary[candidate] as? String else { continue }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
      }
      return nil
    }

    if let direct = firstValue(in: payload) { return direct }

    for container in ["payload", "data"] {
      if let nested = payload[container] as? [AnyHashable: Any],
         let value = firstValue(in: nested) {
        return value
      }
    }
    return nil
  }
}
