import SwiftUI
import UIKit

@main
struct CrazyHenRunApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var yard = Yard()

    var body: some Scene {
        WindowGroup {
            RootFlow()
                .environment(yard)
                .tint(Meadow.moss)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        supportedInterfaceOrientationsFor window: UIWindow?
    ) -> UIInterfaceOrientationMask {
        ScreenGate.allowed
    }
}

enum ScreenGate {
    static var bootFinished = false

    static var allowed: UIInterfaceOrientationMask {
        if !bootFinished { return .all }
        if UIDevice.current.userInterfaceIdiom == .pad { return .all }
        return .portrait
    }

    @MainActor
    static func lockAfterBoot() {
        bootFinished = true
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        }
    }
}

enum Links {
    static let privacy = URL(string: "https://crazyhennrun.com/privacy-policy.html")!
    static let support = URL(string: "https://crazyhennrun.com/support.html")!
    static let mail = "support@crazyhennrun.com"
}

enum Tuning {
    static let metresPerCheck = 250
    static let version = "1.0.4"
}
