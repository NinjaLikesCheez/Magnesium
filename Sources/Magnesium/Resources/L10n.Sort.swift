import Foundation

extension L10n {
    enum Sort {
        static var dateAdded: String {
            NSLocalizedString("sort.date-added", comment: "Date Added")
        }

        static var name: String {
            NSLocalizedString("sort.name", comment: "Name")
        }

        static var downloadSpeed: String {
            NSLocalizedString("sort.download-speed", comment: "Download Speed")
        }

        static var uploadSpeed: String {
            NSLocalizedString("sort.upload-speed", comment: "Upload Speed")
        }

        static func ascending(property: String) -> String {
            let format = NSLocalizedString("sort.direction-ascending", comment: "↑ {property}")
            return .localizedStringWithFormat(format, property)
        }

        static func descending(property: String) -> String {
            let format = NSLocalizedString("sort.direction-descending", comment: "↓ {property}")
            return .localizedStringWithFormat(format, property)
        }
    }
}
