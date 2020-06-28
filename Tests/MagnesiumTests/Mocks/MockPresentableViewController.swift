import Coordinator
import UIKit

class MockPresentableViewController: PresentableViewController {
    private(set) var presentCallCount = 0
    private(set) var presentParamViewController = [UIViewController]()
    private(set) var presentParamAnimated = [Bool]()
    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.present(viewController, animated: flag, completion: completion)
        presentCallCount += 1
        presentParamViewController.append(viewControllerToPresent)
        presentParamAnimated.append(flag)
    }

    private(set) var dismissCallCount = 0
    private(set) var dismissParamAnimated = [Bool]()
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissCallCount += 1
        dismissParamAnimated.append(flag)
    }
}
