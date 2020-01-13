import UIKit

/// A screen that creates a UIAlertController from an AlertModel.
public struct AlertScreen: Navigatable {
    private let model: AlertModel

    /// Creates a new alert screen with the given model.
    /// - Parameter model: The model to use for the created alert.
    public init(_ model: AlertModel) {
        self.model = model
    }

    public func viewController() -> UIViewController? {
        let alertController = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: model.style.alertControllerStyle
        )

        switch model.popoverSource {
        case let .view(view, rect: rect):
            alertController.popoverPresentationController?.sourceView = view
            alertController.popoverPresentationController?.sourceRect = rect
        case let .barButton(barButton):
            alertController.popoverPresentationController?.barButtonItem = barButton
        case .none:
            break
        }

        for action in model.actions {
            alertController.addAction(UIAlertAction(
                title: action.title,
                style: action.style.alertActionStyle,
                handler: { _ in action.handler?() }
            ))
        }

        return alertController
    }
}

private extension AlertModel.Style {
    var alertControllerStyle: UIAlertController.Style {
        switch self {
        case .actionSheet:
            return .actionSheet
        case .alert:
            return .alert
        }
    }
}

private extension AlertActionModel.Style {
    var alertActionStyle: UIAlertAction.Style {
        switch self {
        case .default:
            return .default
        case .cancel:
            return .cancel
        case .destructive:
            return .destructive
        }
    }
}
