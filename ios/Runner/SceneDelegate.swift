import Flutter
import UIKit

/// Scene delegate for Crazy Hen Run.
///
/// The default ``FlutterSceneDelegate`` behaviour is exactly what we want for a
/// portrait-first Flutter app, so this subclass only adds a couple of override
/// hooks that log lifecycle transitions in debug builds. Everything else falls
/// through to the framework implementation.
final class SceneDelegate: FlutterSceneDelegate {

    override func sceneDidBecomeActive(_ scene: UIScene) {
        super.sceneDidBecomeActive(scene)
        #if DEBUG
        NSLog("[Henyard] scene active")
        #endif
    }

    override func sceneWillResignActive(_ scene: UIScene) {
        super.sceneWillResignActive(scene)
        #if DEBUG
        NSLog("[Henyard] scene resigning")
        #endif
    }
}
