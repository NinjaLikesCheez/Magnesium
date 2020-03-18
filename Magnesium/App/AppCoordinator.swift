import Combine
import Coordinator
import MVVMModels
import Preferences
import UIKit

final class AppCoordinator: Coordinator, AlertPresenter {
    private let window: UIWindow
    private let preferences: Preferences
    private let session: Session
    private let splitViewController: PresentableSplitViewController
    private lazy var addTorrentFlow = AddTorrentFlow(viewController: splitViewController, session: session)
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    private var masterNavigationController: PresentableNavigationController = {
        let navigationController = PresentableNavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    var presentable: Presentable {
        splitViewController
    }

    // splitViewController needs to be injected for testing because the detail view controller is difficult to obtain
    // for testing
    init(
        window: UIWindow,
        preferences: Preferences = UserDefaultsPreferences(),
        session: Session? = nil,
        splitViewController: PresentableSplitViewController = PresentableSplitViewController()
    ) {
        self.window = window
        self.preferences = preferences
        self.session = session ?? Session(preferences: preferences)
        self.splitViewController = splitViewController

        self.splitViewController.delegate = self
        self.splitViewController.preferredDisplayMode = .allVisible

        self.session.serverPublisher
            .sink { [weak self] in self?.show(server: $0) }
            .store(in: &cancellables)

        window.rootViewController = splitViewController
        window.makeKeyAndVisible()
    }

    private func show(server: Server?) {
        let viewController: UIViewController
        if let server = server, let viewModel = server.listViewModel(preferences: preferences) {
            let coordinator = TorrentListCoordinator(viewModel: viewModel, session: session, preferences: preferences)
            addChildCoordinator(coordinator) { [weak self] _, event in
                self?.handle(event)
            }
            viewController = coordinator.presentable.viewController
        } else if let server = server {
            let coordinator = ServerErrorCoordinator(server: server)
            addChildCoordinator(coordinator) { [weak self] _, event in
                self?.handle(event)
            }
            viewController = coordinator.presentable.viewController
        } else {
            let coordinator = NoServersCoordinator()
            addChildCoordinator(coordinator) { [weak self] _, event in
                self?.handle(event)
            }
            viewController = coordinator.presentable.viewController
        }

        masterNavigationController.setViewControllers([viewController], animated: false)
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [masterNavigationController, detailNavigationController]
    }

    // internal for testing
    func handle(_ event: TorrentListCoordinatorEvent) {
        switch event {
        case .showSettings:
            showSettings()
        case let .showDetail(viewModel):
            showTorrentDetail(for: viewModel)
        case let .commitDetail(coordinator):
            commitTorrentDetail(for: coordinator)
        case let .torrentsUpdated(hashes):
            handleTorrentsUpdated(hashes: hashes)
        }
    }

    // internal for testing
    func handle(_ event: ServerErrorCoordinatorEvent) {
        switch event {
        case .showSettings:
            showSettings()
        case let .editServer(server):
            showServerSettings(for: server)
        }
    }

    // internal for testing
    func handle(_ event: NoServersCoordinatorEvent) {
        switch event {
        case .showSettings:
            showSettings()
        case .addServer:
            showAddServer()
        }
    }

    private func showSettings() {
        let coordinator = SettingsCoordinator(session: session, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        let viewController = coordinator.presentable.viewController
        viewController.modalPresentationStyle = .formSheet
        splitViewController.present(viewController, animated: true, completion: nil)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: SettingsCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            coordinator.presentable.viewController.dismiss(animated: true)
        }
    }

    private func showAddServer() {
        let coordinator = AddServerCoordinator(preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        let viewController = coordinator.presentable.viewController
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.modalPresentationStyle = .formSheet
        splitViewController.present(navigationController, animated: true, completion: nil)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: AddServerCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            coordinator.presentable.viewController.dismiss(animated: true)
        }
    }

    private func showServerSettings(for server: Server) {
        let coordinator = ServerSettingsCoordinator(server: server, preferences: preferences)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        let viewController = coordinator.presentable.viewController
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.modalPresentationStyle = .formSheet
        splitViewController.present(navigationController, animated: true, completion: nil)
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: ServerSettingsCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            coordinator.presentable.viewController.dismiss(animated: true)
        }
    }

    private func showTorrentDetail(for viewModel: AnyTorrentDetailViewModel) {
        let coordinator = TorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }
        let navigationController = UINavigationController(rootViewController: coordinator.presentable.viewController)
        splitViewController.showDetailViewController(navigationController, sender: nil)
    }

    private func commitTorrentDetail(for coordinator: TorrentDetailCoordinator<AnyTorrentDetailViewModel>) {
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            self?.handle(event, from: coordinator)
        }

        if splitViewController.traitCollection.horizontalSizeClass == .regular {
            UIView.performWithoutAnimation {
                // the navigationController needs to be allocated in the performWithoutAnimation block or else
                // it performs a broken push animation on appear
                let navigationController = UINavigationController(
                    rootViewController: coordinator.presentable.viewController
                )
                splitViewController.showDetailViewController(navigationController, sender: nil)
            }
        } else {
            let navigationController = UINavigationController(
                rootViewController: coordinator.presentable.viewController
            )
            splitViewController.showDetailViewController(navigationController, sender: nil)
        }
    }

    // internal for testing
    func handle<C: Coordinator>(_ event: TorrentDetailCoordinatorEvent, from coordinator: C) {
        switch event {
        case .complete:
            dismissDetailViewController(coordinator.presentable.viewController)
            removeChildCoordinator(coordinator)
        }
    }

    private func dismissDetailViewController(_ viewController: UIViewController) {
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)

        UIView.performWithoutAnimation {
            splitViewController.showDetailViewController(detailNavigationController, sender: nil)
        }

        if masterNavigationController.viewControllers.contains(detailNavigationController) {
            masterNavigationController.popViewController(animated: false)
        }

        let viewController = viewController is UINavigationController
            ? viewController
            : viewController.navigationController ?? viewController
        if let index = masterNavigationController.viewControllers.firstIndex(of: viewController), index > 0 {
            let previousViewController = masterNavigationController.viewControllers[index - 1]
            masterNavigationController.popToViewController(previousViewController, animated: true)
        }
    }

    func add(fileURL: URL) {
        guard let server = session.server else { return }
        var alert = Alert(
            title: L10n.addTorrentToServerPrompt(serverName: server.name),
            message: fileURL.lastPathComponent,
            style: .alert
        )
        alert.addAction(AlertAction(title: L10n.addTorrent, style: .default) {
            self.addTorrentFlow.add(type: .file(fileURL))
        })
        alert.addAction(.cancel)
        showAlert(alert, useTopViewController: true)
    }

    func add(magnetURL: URL) {
        guard let server = session.server else { return }
        var alert = Alert(
            title: L10n.addTorrentToServerPrompt(serverName: server.name),
            message: magnetURL.absoluteString,
            style: .alert
        )
        alert.addAction(AlertAction(title: L10n.addTorrent, style: .default) {
            self.addTorrentFlow.add(type: .magnet(magnetURL))
        })
        alert.addAction(.cancel)
        showAlert(alert, useTopViewController: true)
    }

    private func handleTorrentsUpdated(hashes: [String]) {
        let coordinators = childCoordinators.values
            .compactMap { $0.base as? TorrentDetailCoordinator<AnyTorrentDetailViewModel> }
        for coordinator in coordinators {
            let viewController = coordinator.presentable.viewController
            guard let identifiable = viewController as? TorrentDetailViewControllerIdentifiable,
                !hashes.contains(identifiable.torrentHash)
            else {
                continue
            }

            dismissDetailViewController(coordinator.presentable.viewController)
            removeChildCoordinator(coordinator)
        }
    }
}

extension AppCoordinator: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            !(navigationController.viewControllers.first is TorrentDetailViewControllerIdentifiable) {
            return true
        }

        return false
    }
}
