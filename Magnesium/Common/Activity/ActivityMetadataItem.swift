import LinkPresentation
import UIKit

/// An activity item that provides metadata to display in a share sheet.
final class ActivityMetadataItem: NSObject, UIActivityItemSource {
    private let metadata: LPLinkMetadata

    /// Creates an `ActivityMetadataItem` with the given metadata.
    /// - Parameter metadata: The metadata to provide to a share sheet.
    init(metadata: LPLinkMetadata) {
        self.metadata = metadata
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        false
    }

    func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        nil
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        metadata
    }
}
