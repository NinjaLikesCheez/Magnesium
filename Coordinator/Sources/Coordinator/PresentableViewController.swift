import Combine
import UIKit

open class PresentableViewController: UIViewController, Presentable {
    private let didDismissSubject = PassthroughSubject<Void, Never>()

    public var didDismiss: AnyPublisher<Void, Never> {
        return didDismissSubject.eraseToAnyPublisher()
    }

    public var viewController: UIViewController {
        return self
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if shouldSendDismiss {
            didDismissSubject.send(())
            didDismissSubject.send(completion: .finished)
        }
    }
}
