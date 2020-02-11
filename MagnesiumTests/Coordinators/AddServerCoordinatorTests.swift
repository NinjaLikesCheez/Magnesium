//
//  AddServerCoordinatorTests.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium
import XCTest

class AddServerCoordinatorTests: XCTestCase {
    private let window = UIWindow()
    private let preferences = MockPreferences()
    private var navigationController: UINavigationController!
    private var coordinator: AddServerCoordinator!
    private var observers = [AnyCancellable]()

    override func setUp() {
        super.setUp()
        coordinator = AddServerCoordinator(preferences: preferences)
        navigationController = UINavigationController(rootViewController: coordinator.presentable.viewController)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func test_presentable_shouldBeAddServerViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) == AddServerViewController<AddServerViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController))")
            return
        }
    }

    // MARK: handle - AddServerEvent

    func test_addServerEvent_add_withDeluge_shouldPushDelugeServerSettingsViewController() {
        coordinator.handle(.add(type: .deluge))
        RunLoop.main.run(until: Date())
        let navigationController = coordinator.presentable.viewController.navigationController!
        XCTAssertEqual(navigationController.viewControllers.count, 2)
    }

    // MARK: handle - ServerSettingsCoordinatorEvent

    func test_serverSettingsCoordinator_completeEvent_shouldEmitCompleteEvent() {
        var event: AddServerCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &observers)
        coordinator.handle(ServerSettingsCoordinatorEvent.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }
}
