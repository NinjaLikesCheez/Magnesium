import Foundation

extension L10n {
    enum Action {
        static var ok: String {
            NSLocalizedString("action.ok", comment: "OK")
        }

        static var add: String {
            NSLocalizedString("action.add", comment: "Add")
        }

        static var cancel: String {
            NSLocalizedString("action.cancel", comment: "Cancel")
        }

        static var pause: String {
            NSLocalizedString("action.pause", comment: "Pause")
        }

        static var resume: String {
            NSLocalizedString("action.resume", comment: "Resume")
        }

        static var setLabel: String {
            NSLocalizedString("action.set-label", comment: "Set Label")
        }

        static var verifyFiles: String {
            NSLocalizedString("action.verify-files", comment: "Verify Files")
        }

        static var updateTrackers: String {
            NSLocalizedString("action.update-trackers", comment: "Update Trackers")
        }

        static var remove: String {
            NSLocalizedString("action.remove", comment: "Remove")
        }

        static var save: String {
            NSLocalizedString("action.save", comment: "Save")
        }

        static var addServer: String {
            NSLocalizedString("action.add-server", comment: "Add Server")
        }

        static var editServer: String {
            NSLocalizedString("action.edit-server", comment: "Edit Server")
        }

        static var deleteServer: String {
            NSLocalizedString("action.delete-server", comment: "Delete Server")
        }

        static var delete: String {
            NSLocalizedString("action.delete", comment: "Delete")
        }

        static var moveDownloadFolder: String {
            NSLocalizedString("action.move-download-folder", comment: "Move Download Folder")
        }

        static var addTorrent: String {
            NSLocalizedString("action.add-torrent", comment: "Add Torrent")
        }

        static var edit: String {
            NSLocalizedString("action.edit", comment: "Edit")
        }

        static var setPriority: String {
            NSLocalizedString("action.set-priority", comment: "Set Priority")
        }

        static var selectAll: String {
            NSLocalizedString("action.select-all", comment: "Select All")
        }
    }
}
