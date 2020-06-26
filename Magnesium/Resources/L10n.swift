import Foundation

enum L10n {
    enum Screen {}

    enum Common {
        static func selectedCount(_ count: Int) -> String {
            let format = NSLocalizedString("selected-count", comment: "{number} Selected")
            return .localizedStringWithFormat(format, count)
        }
    }
}
