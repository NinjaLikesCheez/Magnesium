import Foundation

public enum Formatters {
	public static var eta: Duration.UnitsFormatStyle {
		Duration.UnitsFormatStyle(
			allowedUnits: [.days, .hours, .minutes, .seconds],
			width: .narrow
		)
		.locale(.autoupdatingCurrent)
	}

	public static func float<T: BinaryFloatingPoint>(precision: Int) -> FloatingPointFormatStyle<T> {
		FloatingPointFormatStyle<T>()
			.locale(.autoupdatingCurrent)
			.precision(.fractionLength(precision...precision))
			.rounded()
	}

	public static func number<T: BinaryInteger>(precision: Int) -> IntegerFormatStyle<T> {
		IntegerFormatStyle<T>()
			.locale(.autoupdatingCurrent)
			.precision(.fractionLength(precision...precision))
	}

	public static var number: IntegerFormatStyle<Int> {
		number(precision: 0)
	}

	public static var float: FloatingPointFormatStyle<Double> {
		float(precision: 0)
	}

	public static func percentage<T: BinaryInteger>(precision: Int) -> IntegerFormatStyle<T>.Percent {
		IntegerFormatStyle<T>.Percent()
			.precision(.fractionLength(precision...precision))
			.locale(.autoupdatingCurrent)
			.rounded()
	}

	public static func percentage<T: BinaryFloatingPoint>(precision: Int) -> FloatingPointFormatStyle<T>.Percent {
		FloatingPointFormatStyle<T>.Percent()
			.precision(.fractionLength(precision...precision))
			.locale(.autoupdatingCurrent)
			.rounded()
	}

	public static var percentage: FloatingPointFormatStyle<Double>.Percent {
		percentage(precision: 0)
	}

	public static var percentageFloat: FloatingPointFormatStyle<Float>.Percent {
		percentage(precision: 0)
	}

	public static var bytes: ByteCountFormatStyle {
		ByteCountFormatStyle(
			style: .binary,
			allowedUnits: .all.subtracting(.bytes),
			spellsOutZero: false,
			includesActualByteCount: false,
			locale: .autoupdatingCurrent
		)
	}
}
