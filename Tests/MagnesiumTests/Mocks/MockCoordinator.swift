import Combine
import Coordinator
import UIKit

class MockCoordinator<T: Presentable & UIViewController>: Coordinator {
    let viewController: T
    let eventPublisher: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    let viewModelEventPublisher: AnyPublisher<Never, Never> = Empty().eraseToAnyPublisher()
    var cancellables = Set<AnyCancellable>()
    var childCoordinators = [AnyHashable: AnyCoordinator]()
    var presentable: Presentable { viewController }

    init(viewController: T) {
        self.viewController = viewController
    }
}
