import MVVMModels
import UIKit

extension Activity {
    static func setLabel(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.setLabel,
            image: UIImage(systemName: "tag"),
            type: "ca.jameshurst.Magnesium.set-label",
            handler: handler
        )
    }

    static func verifyFiles(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.verifyFiles,
            image: UIImage(systemName: "tray.full"),
            type: "ca.jameshurst.Magnesium.verify-files",
            handler: handler
        )
    }

    static func updateTrackers(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.updateTrackers,
            image: UIImage(systemName: "arrow.clockwise"),
            type: "ca.jameshurst.Magnesium.update-trackers",
            handler: handler
        )
    }

    static func moveDownloadFolder(handler: @escaping () -> Void) -> Activity {
        return Activity(
            title: L10n.moveDownloadFolder,
            image: UIImage(systemName: "tray.and.arrow.down"),
            type: "ca.jameshurst.Magnesium.move-download-folder",
            handler: handler
        )
    }
}
