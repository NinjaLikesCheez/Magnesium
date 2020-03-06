import UIKit

/// A model describing an activity.
struct Activity {
    /// The title of the activity.
    var title: String
    /// The image displayed with the activity.
    var image: UIImage?
    /// A unique identifier for the type of action. This is typically in reverse DNS format.
    var type: String
    /// The handler to run when the activity is selected.
    var handler: () -> Void
}
