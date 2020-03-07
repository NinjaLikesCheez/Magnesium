/// A model describing an alert.
struct Alert {
    /// The presentation styles of an alert.
    enum Style {
        case actionSheet
        case alert
    }

    /// The title of the alert.
    var title: String?
    /// A message that provides more information about the alert.
    var message: String?
    /// The presentation style of the alert.
    var style: Style
    /// The actions presented by the alert.
    var actions = [AlertAction]()

    /// Appends an action to the alert.
    /// - Parameter action: An action to append to the alert.
    mutating func addAction(_ action: AlertAction) {
        actions.append(action)
    }
}
