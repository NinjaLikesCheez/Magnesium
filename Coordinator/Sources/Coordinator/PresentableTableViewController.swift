import Combine
import UIKit

open class PresentableTableViewController: UITableViewController, Presentable {
    private let didDismissSubject = PassthroughSubject<Void, Never>()

    open var didDismiss: AnyPublisher<Void, Never> {
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
