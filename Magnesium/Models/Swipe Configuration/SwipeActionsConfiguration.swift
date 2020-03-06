/// A model describing the swipe actions for a cell.
struct SwipeActionsConfiguration {
    /// The swipe actions.
    var actions: [SwipeAction]
    /// Whether a full swipe automatically performs the first action.
    var performsFirstActionWithFullSwipe = true
}
