import Coordinator
import MVVMModels
import UIKit

protocol AlertPresenter {
    func showAlert(_ alert: Alert, useTopViewController: Bool)
}

extension AlertPresenter where Self: Coordinator {
    func showAlert(_ alert: Alert, useTopViewController: Bool = false) {
        let alertController = alert.createAlertController()

        if useTopViewController {
            var current = presentable.viewController
            while let next = current.presentedViewController {
                current = next
            }
            current.present(alertController, animated: true)
        } else {
            presentable.viewController.present(alertController, animated: true)
        }
    }
}
