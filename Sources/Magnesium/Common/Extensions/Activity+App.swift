import CommonModels
import UIKit

extension Activity {
    static func setLabel(handler: @escaping () -> Void) -> Activity {
        .init(
            title: L10n.Action.setLabel,
            image: UIImage(systemName: "tag"),
            type: "ca.jameshurst.Magnesium.set-label",
            handler: handler
        )
    }

    static func verifyFiles(handler: @escaping () -> Void) -> Activity {
        .init(
            title: L10n.Action.verifyFiles,
            image: UIImage(systemName: "tray.full"),
            type: "ca.jameshurst.Magnesium.verify-files",
            handler: handler
        )
    }

    static func updateTrackers(handler: @escaping () -> Void) -> Activity {
        .init(
            title: L10n.Action.updateTrackers,
            image: UIImage(systemName: "arrow.clockwise"),
            type: "ca.jameshurst.Magnesium.update-trackers",
            handler: handler
        )
    }

    static func moveDownloadFolder(handler: @escaping () -> Void) -> Activity {
        .init(
            title: L10n.Action.moveDownloadFolder,
            image: UIImage(systemName: "tray.and.arrow.down"),
            type: "ca.jameshurst.Magnesium.move-download-folder",
            handler: handler
        )
    }

    static func copyDownloadPaths(handler: @escaping () -> Void) -> Activity {
        .init(
            title: L10n.Action.copyDownloadPaths,
            image: UIImage(systemName: "doc.on.doc"),
            type: "ca.jameshurt.Magnesium.copy-download-path",
            handler: handler
        )
    }
}
