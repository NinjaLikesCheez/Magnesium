import Foundation

enum Formatters {
    static var eta: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static var numberFormatters = [Int: NumberFormatter]()
    static func number(precision: Int) -> NumberFormatter {
        if let formatter = numberFormatters[precision] {
            return formatter
        }

        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        numberFormatters[precision] = formatter
        return formatter
    }

    static var number: NumberFormatter {
        return number(precision: 0)
    }

    private static var percentageFormatters = [Int: NumberFormatter]()
    static func percentage(precision: Int) -> NumberFormatter {
        if let formatter = percentageFormatters[precision] {
            return formatter
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = precision
        formatter.maximumFractionDigits = precision
        percentageFormatters[precision] = formatter
        return formatter
    }

    static var percentage: NumberFormatter {
        return percentage(precision: 0)
    }

    static var bytes: ByteCountFormatter = {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        formatter.allowsNonnumericFormatting = false
        formatter.allowedUnits = ByteCountFormatter.Units.useAll.subtracting(.useBytes)
        formatter.zeroPadsFractionDigits = true
        return formatter
    }()
}
