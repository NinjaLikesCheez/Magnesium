import Foundation

extension L10n.Screen {
    enum RefreshInterval {
        static var title: String {
            NSLocalizedString("screen.refresh-interval.title", comment: "Refresh Interval")
        }

        static var never: String {
            NSLocalizedString("screen.refresh-interval.never", comment: "Never")
        }

        static func seconds(_ seconds: Int) -> String {
            let format = NSLocalizedString("screen.refresh-interval.seconds", comment: "{number} seconds")
            return .localizedStringWithFormat(format, seconds)
        }
    }
}
