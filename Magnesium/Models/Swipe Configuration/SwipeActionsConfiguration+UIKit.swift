import UIKit

extension SwipeActionsConfiguration {
    func createUISwipeActionsConfiguration() -> UISwipeActionsConfiguration {
        let configuration = UISwipeActionsConfiguration(actions: actions.map { action in
            let uiAction = UIContextualAction(
                style: action.style.contextualActionStyle,
                title: action.title,
                handler: { _, _, complete in
                    action.handler()
                    complete(true)
                }
            )
            uiAction.backgroundColor = action.backgroundColor
            uiAction.image = action.image
            return uiAction
        })
        configuration.performsFirstActionWithFullSwipe = performsFirstActionWithFullSwipe
        return configuration
    }
}

private extension SwipeAction.Style {
    var contextualActionStyle: UIContextualAction.Style {
        switch self {
        case .normal:
            return .normal
        case .destructive:
            return .destructive
        }
    }
}
