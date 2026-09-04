import Flutter
import UIKit
import UserNotifications

/// Application entry point for Crazy Hen Run on iOS.
///
/// Flutter's implicit engine is used, so plugins are registered when the
/// engine finishes spinning up rather than in ``application(_:didFinishLaunchingWithOptions:)``.
/// A small ``LaunchTelemetry`` helper records a few timestamps so we can debug
/// long cold starts against release builds without pulling in a full analytics
/// SDK.
@main
@objc final class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    private let launchTelemetry = LaunchTelemetry()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        launchTelemetry.mark(.didFinishLaunching)
        UNUserNotificationCenter.current().delegate = self
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func applicationDidBecomeActive(_ application: UIApplication) {
        launchTelemetry.mark(.didBecomeActive)
        super.applicationDidBecomeActive(application)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        launchTelemetry.mark(.engineReady)
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }
}

/// Tiny in-memory stopwatch used only during development.
///
/// It is intentionally lightweight – no dependencies, no persistence, no
/// networking – and simply keeps the last timestamp for each named phase so
/// debug builds can print a summary in the console.
private final class LaunchTelemetry {

    enum Phase: String, CaseIterable {
        case didFinishLaunching
        case engineReady
        case didBecomeActive
    }

    private let bootTime = Date()
    private var timestamps: [Phase: TimeInterval] = [:]

    func mark(_ phase: Phase) {
        let elapsed = Date().timeIntervalSince(bootTime)
        timestamps[phase] = elapsed
        #if DEBUG
        let ms = Int((elapsed * 1000).rounded())
        NSLog("[Henyard] %@ +%dms", phase.rawValue, ms)
        #endif
    }
}
