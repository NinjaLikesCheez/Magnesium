import UIKit

/// The source of a popover presentation.
enum PopoverSource {
    /// The view and frame to present the popover from.
    case view(UIView, rect: CGRect)
    /// The bar button item to present the popover from.
    case barButton(UIBarButtonItem)
}

extension UIViewController {
    /// Configures the viewController's the `popoverPresentationController`.
    /// - Parameter source: The source for a popover presentation.
    func configure(popoverSource source: PopoverSource?) {
        switch source {
        case let .view(view, rect: rect):
            popoverPresentationController?.sourceView = view
            popoverPresentationController?.sourceRect = rect
        case let .barButton(barButtonItem):
            popoverPresentationController?.barButtonItem = barButtonItem
        case .none:
            break
        }
    }
}
