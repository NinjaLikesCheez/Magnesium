import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private var coordinator: AppCoordinator?
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let isRunningTests = NSClassFromString("XCTestCase") != nil
        guard !isRunningTests else {
            if let windowScene = scene as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.rootViewController = UIViewController()
                self.window = window
                window.makeKeyAndVisible()
            }
            return
        }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            self.window = window
            coordinator = AppCoordinator(window: window)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url, url.pathExtension == "torrent" else { return }
        coordinator?.addTorrentFile(at: url)
    }
}
