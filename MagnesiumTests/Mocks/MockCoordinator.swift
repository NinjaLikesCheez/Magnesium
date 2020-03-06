import Combine
import Coordinator
import UIKit

class MockCoordinator<T: Presentable & UIViewController>: Coordinator {
    let viewController: T
    let events: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let received: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var observers = [AnyCancellable]()
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var presentable: Presentable { viewController }

    init(viewController: T) {
        self.viewController = viewController
    }
}
