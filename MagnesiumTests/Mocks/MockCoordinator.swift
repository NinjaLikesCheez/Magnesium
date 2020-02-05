//
//  MockCoordinator.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-04.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Coordinator

open class MockCoordinator: Coordinator {
    public let viewController = MockPresentableViewController()
    public let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    public let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    open var observers = [AnyCancellable]()
    open var childCoordinators = [AnyHashable: AnyCoordinator]()
    open var presentable: Presentable { viewController }
}
