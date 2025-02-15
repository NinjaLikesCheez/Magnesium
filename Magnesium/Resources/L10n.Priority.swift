import Foundation

extension L10n {
    enum Priority {
        static var disabled: String {
            NSLocalizedString("priority.disabled", comment: "Disabled")
        }

        static var low: String {
            NSLocalizedString("priority.low", comment: "Low Priority")
        }

        static var normal: String {
            NSLocalizedString("priority.normal", comment: "Normal Priority")
        }

        static var high: String {
            NSLocalizedString("priority.high", comment: "High Priority")
        }
    }
}
