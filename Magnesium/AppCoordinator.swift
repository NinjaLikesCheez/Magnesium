//
//  AppCoordinator.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-16.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
import Preferences
import UIKit

final class AppCoordinator: Coordinator, AlertPresenter {
    private let window: UIWindow
    private lazy var session: Session = DefaultSession(preferences: preferences)
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()

    private var preferences: Preferences = {
        let preferences = UserDefaultsPreferences()
        _ = try? preferences.registerDefault(2, for: PreferenceKeys.autoRefreshInterval)
        return preferences
    }()

    private lazy var splitViewController: PresentableSplitViewController = {
        let splitViewController = PresentableSplitViewController()
        splitViewController.delegate = self
        splitViewController.preferredDisplayMode = .allVisible
        return splitViewController
    }()

    private var masterNavigationController: PresentableNavigationController = {
        let navigationController = PresentableNavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }()

    var presentable: Presentable {
        return splitViewController
    }

    init(window: UIWindow) {
        self.window = window
        session.serverPublisher
            .sink { [weak self] in self?.show(server: $0) }
            .store(in: &observers)
        window.rootViewController = splitViewController
        window.makeKeyAndVisible()
    }

    private func show(server: Server?) {
        let listCoordinator = DefaultTorrentListCoordinator(server: server, session: session, preferences: preferences)
        addChildCoordinator(listCoordinator) { [weak self] _, event in
            switch event {
            case .settings:
                self?.showSettings()
            case let .detail(viewModel: viewModel):
                self?.showTorrentDetail(viewModel: viewModel)
            }
        }
        masterNavigationController.setViewControllers([listCoordinator.presentable.viewController], animated: false)
        let detailViewController = UIViewController()
        detailViewController.view.backgroundColor = .systemGroupedBackground
        let detailNavigationController = UINavigationController(rootViewController: detailViewController)
        splitViewController.viewControllers = [masterNavigationController, detailNavigationController]
    }

    private func showSettings() {
        let coordinator = DefaultSettingsCoordinator(session: session, preferences: preferences)
        addChildCoordinator(coordinator) { coordinator, event in
            switch event {
            case .complete:
                coordinator.presentable.viewController.dismiss(animated: true)
            }
        }
        let viewController = coordinator.presentable.viewController
        viewController.modalPresentationStyle = .formSheet
        splitViewController.present(viewController, animated: true, completion: nil)
    }

    private func showTorrentDetail(viewModel: TorrentDetailViewModel) {
        let coordinator = DefaultTorrentDetailCoordinator(viewModel: viewModel)
        addChildCoordinator(coordinator) { [weak self] coordinator, event in
            switch event {
            case .complete:
                self?.dismissDetailViewController(coordinator.presentable.viewController)
            }
        }
        splitViewController.showDetailViewController(coordinator.presentable.viewController, sender: nil)
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

    func addTorrentFile(at url: URL) {
        guard let server = session.server else { return }
        var alert = Alert(
            title: "Add Torrent",
            message: "Add \(url.lastPathComponent) to \(server.name)?",
            style: .alert
        )
        alert.addAction(AlertAction(title: "Add", style: .default) {
            self.addTorrentFile(at: url, to: server)
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        showAlert(alert, useTopViewController: true)
    }

    private func addTorrentFile(at url: URL, to server: Server) {
        var isAccessingSecurityScopedResource = false
        if !FileManager.default.isReadableFile(atPath: url.absoluteString) {
            _ = url.startAccessingSecurityScopedResource()
            isAccessingSecurityScopedResource = true
        }

        defer {
            if isAccessingSecurityScopedResource {
                url.stopAccessingSecurityScopedResource()
            }
        }

        switch server.type {
        case .deluge:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(DelugeServerSettings.self, from: server.data),
                let keychain = try? decoder.decode(DelugeKeychainData.self, from: server.data)
            else {
                return
            }

            let client = DefaultDelugeClient(
                baseURL: settings.url,
                password: keychain.password
            )
            client.add(fileURL: url)
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
                    }, receiveValue: { _ in })
                .store(in: &observers)
        case .transmission:
            let decoder = JSONDecoder()
            guard let settings = try? decoder.decode(TransmissionServerSettings.self, from: server.data),
                let keychain = try? decoder.decode(TransmissionKeychainData.self, from: server.data)
            else {
                return
            }

            let client = DefaultTransmissionClient(
                baseURL: settings.url,
                username: settings.username,
                password: keychain.password
            )
            client.add(fileURL: url)
                .ui()
                .sink(receiveCompletion: { [weak self] completion in
                    guard case let .failure(error) = completion else { return }
                    self?.showError(title: "Failed to Add Torrent", message: error.localizedDescription)
                }, receiveValue: { _ in })
                .store(in: &observers)
        }
    }

    private func showError(title: String, message: String?) {
        var alert = Alert(
            title: title,
            message: message,
            style: .alert
        )
        alert.addAction(AlertAction(title: "OK", style: .default))
        showAlert(alert, useTopViewController: true)
    }
}

extension AppCoordinator: UISplitViewControllerDelegate {
    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        if let navigationController = secondaryViewController as? UINavigationController,
            !(navigationController.viewControllers.first is TorrentDetailViewController) {
            return true
        }

        return false
    }
}
