import Foundation

// TODO: rewrite all of these to use https://developer.apple.com/documentation/foundation/measurement/formatstyle they cache automatically to!

enum Formatters {
	static var eta: Duration.UnitsFormatStyle = {
		Duration.UnitsFormatStyle(
			allowedUnits: [.days, .hours, .minutes, .seconds],
			width: .narrow
		)
		.locale(Current.locale)

//		Date.FormatStyle(
//			date: .omitted,
//			time: .shortened,
//			locale: Current.locale,
//			calendar: Current.calendar
//		)
//			.locale(Current.locale)
//		let formatter = DateComponentsFormatter()
//		formatter.calendar = Current.calendar
//		formatter.allowedUnits = [.day, .hour, .minute, .second]
//		formatter.unitsStyle = .abbreviated
//		return formatter
	}()

	static func float<T: BinaryFloatingPoint>(precision: Int) -> FloatingPointFormatStyle<T> {
		FloatingPointFormatStyle<T>()
			.locale(Current.locale)
			.precision(.fractionLength(precision...precision))
			.rounded()
	}

	static func number<T: BinaryInteger>(precision: Int) -> IntegerFormatStyle<T> {
		IntegerFormatStyle<T>()
			.locale(Current.locale)
			.precision(.fractionLength(precision...precision))
//		if let formatter = numberFormatters[precision] {
//			return formatter
//		}
//
//		let formatter = NumberFormatter()
//		formatter.locale = Current.locale
//		formatter.minimumFractionDigits = precision
//		formatter.maximumFractionDigits = precision
//		numberFormatters[precision] = formatter
//		return formatter
	}

	static var number: IntegerFormatStyle<Int> {
		number(precision: 0)
	}

	static var float: FloatingPointFormatStyle<Double> {
		float(precision: 0)
	}

	private static var percentageFormatters = [Int: NumberFormatter]()
	static func percentage<T: BinaryInteger>(precision: Int) -> IntegerFormatStyle<T>.Percent {
		IntegerFormatStyle<T>.Percent()
			.precision(.fractionLength(precision...precision))
			.locale(Current.locale)
			.rounded()

		// TODO: see if FormatStyling will cache for us - breaks in tests
	}

	static func percentage<T: BinaryFloatingPoint>(precision: Int) -> FloatingPointFormatStyle<T>.Percent {
		FloatingPointFormatStyle<T>.Percent()
			.precision(.fractionLength(precision...precision))
			.locale(Current.locale)
			.rounded()

		// TODO: see if FormatStyling will cache for us - breaks in tests
	}

	static var percentage: FloatingPointFormatStyle<Double>.Percent {
		percentage(precision: 0)
	}

	static var percentageFloat: FloatingPointFormatStyle<Float>.Percent {
		percentage(precision: 0)
	}

	static var bytes: ByteCountFormatStyle = {
		ByteCountFormatStyle(
			style: .binary,
			allowedUnits: .all.subtracting(.bytes),
			spellsOutZero: true,
			includesActualByteCount: false,
			locale: Current.locale
		)
	}()
}
