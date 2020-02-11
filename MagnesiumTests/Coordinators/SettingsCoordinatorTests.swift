//
//  SettingsCoordinatorTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator
@testable import Magnesium
import SwiftUI
import XCTest

class SettingsCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = MockPreferences()
    private lazy var session = Session(preferences: preferences)
    private var coordinator: SettingsCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = SettingsCoordinator(session: session, preferences: preferences)

        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeNavigationController_withSettingsViewController() {
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[0]
        guard type(of: viewController) === SettingsViewController<SettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - SettingsEvent

    func test_settingsEvent_complete_shouldEmitCompleteEvent() {
        var event: SettingsCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        coordinator.handle(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_settingsEvent_alert_shouldPresentAlertController() {
        coordinator.handle(.alert(Alert(title: "", message: nil, style: .alert), source: nil))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_edit_withTransmissionServer_shouldPushServerSettingsViewController() {
        coordinator.handle(.edit(server: .transmissionMock()))
        RunLoop.main.run(until: Date())
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_edit_withDelugeServer_shouldPushServerSettingsViewController() {
        coordinator.handle(.edit(server: .delugeMock()))
        RunLoop.main.run(until: Date())
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === ServerSettingsViewController<AnyServerSettingsViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_addServer_shouldPushAddServerViewController() {
        coordinator.handle(.addServer)
        RunLoop.main.run(until: Date())
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === AddServerViewController<AddServerViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_refreshInterval_shouldPushRefreshIntervalViewController() {
        coordinator.handle(.refreshInterval)
        RunLoop.main.run(until: Date())
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        guard type(of: viewController) === RefreshIntervalViewController<RefreshIntervalViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    func test_settingsEvent_advancedSettings_shouldPushAdvancedSettingsViewController() {
        coordinator.handle(.advancedSettings)
        RunLoop.main.run(until: Date())
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController
        let viewController = navigationController.viewControllers[1]
        let expectedType = UIHostingController<AdvancedSettingsView<AdvancedSettingsViewModel>>.self
        guard type(of: viewController) === expectedType else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: - ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinator_completeEvent_shouldPopViewController() {
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController

        coordinator.handle(.edit(server: .transmissionMock()))
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 2)

        let coordinator = MockCoordinator(
            // swiftlint:disable:next force_cast
            viewController: navigationController.viewControllers[1] as! PresentableTableViewController
        )
        self.coordinator.handle(ServerSettingsCoordinatorEvent.complete, from: coordinator)
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }

    // MARK: - AddServerCoordinatorEvent

    func test_addServerCoordinatorEvent_completeEvent_shouldPopRootViewController() {
        // swiftlint:disable:next force_cast
        let navigationController = coordinator.presentable.viewController as! UINavigationController

        coordinator.handle(.edit(server: .transmissionMock()))
        RunLoop.main.run(until: Date())
        navigationController.pushViewController(UIViewController(), animated: false)
        XCTAssertEqual(navigationController.viewControllers.count, 3)

        let coordinator = MockCoordinator(
            // swiftlint:disable:next force_cast
            viewController: navigationController.viewControllers[1] as! PresentableTableViewController
        )
        self.coordinator.handle(AddServerCoordinatorEvent.complete, from: coordinator)
        RunLoop.main.run(until: Date())
        XCTAssertEqual(navigationController.viewControllers.count, 1)
    }
}
