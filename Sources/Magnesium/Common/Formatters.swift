import Foundation

enum Formatters {
	static var eta: Duration.UnitsFormatStyle = {
		Duration.UnitsFormatStyle(
			allowedUnits: [.days, .hours, .minutes, .seconds],
			width: .narrow
		)
		.locale(Current.locale)
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
	}

	static func percentage<T: BinaryFloatingPoint>(precision: Int) -> FloatingPointFormatStyle<T>.Percent {
		FloatingPointFormatStyle<T>.Percent()
			.precision(.fractionLength(precision...precision))
			.locale(Current.locale)
			.rounded()
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
