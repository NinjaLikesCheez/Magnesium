import Common
import Foundation
import Testing

@testable import Magnesium

@Suite("Formatters Tests")
struct FormattersTests {
	// MARK: - Byte Count Formatting Tests

	@Suite("Byte Count Formatting Tests")
	struct ByteCountFormattingTests {

		@Test("Format bytes with various sizes")
		func formatBytesWithVariousSizes() {
			let locale = Locale(identifier: "en_US")

			// Test small values
			// TODO: https://developer.apple.com/documentation/foundation/formatstyle/bytecount(style:allowedunits:spellsoutzero:includesactualbytecount:)-59ep0
			let zero: Int64 = 0
			let fiveTwelve: Int64 = 512
			let oneKB: Int64 = 1024
			#expect(zero.formatted(Formatters.bytes.locale(locale)) == "0 kB")
			#expect(fiveTwelve.formatted(Formatters.bytes.locale(locale)) == "0 kB")
			#expect(oneKB.formatted(Formatters.bytes.locale(locale)) == "1 kB")

			// Test KB range
			let twoKB: Int64 = 2048
			let oneAndHalfKB: Int64 = 1536
			#expect(twoKB.formatted(Formatters.bytes.locale(locale)) == "2 kB")
			#expect(oneAndHalfKB.formatted(Formatters.bytes.locale(locale)) == "2 kB")

			// Test MB range
			let oneMB: Int64 = 1024 * 1024
			let twoMB: Int64 = 1024 * 1024 * 2
			let oneAndHalfMB: Int64 = 1024 * 1024 + 512 * 1024
			#expect(oneMB.formatted(Formatters.bytes.locale(locale)) == "1 MB")
			#expect(twoMB.formatted(Formatters.bytes.locale(locale)) == "2 MB")
			#expect(oneAndHalfMB.formatted(Formatters.bytes.locale(locale)) == "1.5 MB")

			// Test GB range
			let oneGB: Int64 = 1024 * 1024 * 1024
			let fiveGB: Int64 = Int64(1024) * 1024 * 1024 * 5
			#expect(oneGB.formatted(Formatters.bytes.locale(locale)) == "1 GB")
			#expect(fiveGB.formatted(Formatters.bytes.locale(locale)) == "5 GB")

			// Test TB range
			let oneTB: Int64 = Int64(1024) * 1024 * 1024 * 1024
			#expect(oneTB.formatted(Formatters.bytes.locale(locale)) == "1 TB")
		}

		@Test("Format bytes with binary units")
		func formatBytesWithBinaryUnits() {
			// Verify binary (1024-based) counting is used
			let oneMB = 1024 * 1024
			let result = Int64(oneMB).formatted(Formatters.bytes.locale(.init(identifier: "en_US")))
			#expect(result == "1 MB")

			// Test that decimal (1000-based) would be different
			let oneDecimalMB = 1000 * 1000
			let decimalResult = Int64(oneDecimalMB).formatted(Formatters.bytes.locale(.init(identifier: "en_US")))
			#expect(decimalResult != "1 MB")  // Should be less than 1.0 MB in binary
		}

		@Test("Format bytes excludes byte unit")
		func formatBytesExcludesByteUnit() {
			// Verify that bytes unit is not used (minimum is KB)
			let result = 100.formatted(Formatters.bytes.locale(.init(identifier: "en_US")))
			#expect(!result.contains("bytes"))
			#expect(!result.contains("B "))  // Space after B would indicate bytes unit
		}

		@Test("Format large byte values")
		func formatLargeByteValues() {
			// Test very large values
			let petabyte = Int64(1024) * 1024 * 1024 * 1024 * 1024
			let result = petabyte.formatted(Formatters.bytes.locale(.init(identifier: "en_US")))
			#expect(result.contains("PB") || result.contains("TB"))  // Should handle large values
		}
	}

	// MARK: - Percentage Formatting Tests

	@Suite("Percentage Formatting Tests")
	struct PercentageFormattingTests {

		@Test("Format percentage with default precision")
		func formatPercentageWithDefaultPrecision() {
			// Use Double values for formatting
			#expect(0.0.formatted(Formatters.percentage.locale(.init(identifier: "en_US"))) == "0%")
			#expect(0.5.formatted(Formatters.percentage.locale(.init(identifier: "en_US"))) == "50%")
			#expect(1.0.formatted(Formatters.percentage.locale(.init(identifier: "en_US"))) == "100%")
			#expect(0.123.formatted(Formatters.percentage.locale(.init(identifier: "en_US"))) == "12%")
		}

		@Test("Format percentage with custom precision")
		func formatPercentageWithCustomPrecision() {
			// Test 1 decimal place
			#expect(0.123.formatted(Formatters.percentage(precision: 1).locale(.init(identifier: "en_US"))) == "12.3%")
			#expect(0.1234.formatted(Formatters.percentage(precision: 1).locale(.init(identifier: "en_US"))) == "12.3%")

			// Test 2 decimal places
			#expect(0.123.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "12.30%")
			#expect(0.1234.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "12.34%")
		}

		@Test("Format percentage with various precision levels")
		func formatPercentageWithVariousPrecisionLevels() {
			let value = 0.123456

			#expect(value.formatted(Formatters.percentage(precision: 0).locale(.init(identifier: "en_US"))) == "12%")
			#expect(value.formatted(Formatters.percentage(precision: 1).locale(.init(identifier: "en_US"))) == "12.3%")
			#expect(value.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "12.35%")
			#expect(value.formatted(Formatters.percentage(precision: 3).locale(.init(identifier: "en_US"))) == "12.346%")
		}

		@Test("Format percentage edge cases")
		func formatPercentageEdgeCases() {
			// Test edge values
			#expect(0.0.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "0.00%")
			#expect(1.0.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "100.00%")

			// Test values over 100%
			#expect(1.5.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "150.00%")
			#expect(2.0.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "200.00%")

			// Test very small values
			#expect(0.001.formatted(Formatters.percentage(precision: 2).locale(.init(identifier: "en_US"))) == "0.10%")
		}
	}

	// MARK: - Number Formatting Tests

	@Suite("Number Formatting Tests")
	struct NumberFormattingTests {

		@Test("Format number with default precision")
		func formatNumberWithDefaultPrecision() {
			#expect(0.formatted(Formatters.number) == "0")
			#expect(123.formatted(Formatters.number) == "123")
			#expect(123.456.formatted(Formatters.float) == "123")
		}

		@Test("Format number with custom precision")
		func formatNumberWithCustomPrecision() {
			// Test 1 decimal place
			#expect(123.456.formatted(Formatters.float(precision: 1).locale(.init(identifier: "en_US"))) == "123.5")
			#expect(123.formatted(Formatters.number(precision: 1).locale(.init(identifier: "en_US"))) == "123.0")

			// Test 2 decimal places
			#expect(123.456.formatted(Formatters.float(precision: 2).locale(.init(identifier: "en_US"))) == "123.46")
			#expect(123.formatted(Formatters.number(precision: 2).locale(.init(identifier: "en_US"))) == "123.00")
		}

		@Test("Format number with various precision levels")
		func formatNumberWithVariousPrecisionLevels() {
			let value = 123.456789

			#expect(value.formatted(Formatters.float(precision: 0).locale(.init(identifier: "en_US"))) == "123")
			#expect(value.formatted(Formatters.float(precision: 1).locale(.init(identifier: "en_US"))) == "123.5")
			#expect(value.formatted(Formatters.float(precision: 2).locale(.init(identifier: "en_US"))) == "123.46")
			#expect(value.formatted(Formatters.float(precision: 3).locale(.init(identifier: "en_US"))) == "123.457")
		}

		@Test("Format negative numbers")
		func formatNegativeNumbers() {
			#expect((-123.456).formatted(Formatters.float(precision: 2).locale(.init(identifier: "en_US"))) == "-123.46")
			#expect((-0.1).formatted(Formatters.float(precision: 2).locale(.init(identifier: "en_US"))) == "-0.10")
		}
	}

	// MARK: - ETA Formatting Tests

	@Suite("ETA Formatting Tests")
	struct ETAFormattingTests {

		@Test("Format ETA with various time intervals")
		func formatETAWithVariousTimeIntervals() {
			// Test seconds
			#expect(Duration.seconds(30).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "30s")
			#expect(Duration.seconds(59).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "59s")

			// Test minutes
			#expect(Duration.seconds(60).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1m")
			#expect(Duration.seconds(90).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1m 30s")
			#expect(Duration.seconds(3600 - 1).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "59m 59s")

			// Test hours
			#expect(Duration.seconds(3600).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1h")
			#expect(Duration.seconds(3660).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1h 1m")
			#expect(Duration.seconds(7200).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "2h")

			// Test days
			#expect(Duration.seconds(86400).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1d")
			#expect(Duration.seconds(90000).formatted(Formatters.eta.locale(.init(identifier: "en_US"))) == "1d 1h")
		}

		@Test("Format ETA with zero and negative values")
		func formatETAWithZeroAndNegativeValues() {
			// Test zero
			let zeroResult = Duration.seconds(0).formatted(Formatters.eta.locale(.init(identifier: "en_US")))
			#expect(zeroResult == "0s")  // Should handle zero gracefully

			// Test negative (should handle gracefully)
			let negativeResult = Duration.seconds(-100).formatted(Formatters.eta.locale(.init(identifier: "en_US")))
			#expect(negativeResult == "-1m 40s")  // Should not crash
		}

		@Test("Format ETA with large time intervals")
		func formatETAWithLargeTimeIntervals() {
			// Test weeks (7 days)
			let result = Duration.seconds(7 * 24 * 3600).formatted(Formatters.eta.locale(.init(identifier: "en_US")))
			#expect(result == "7d")  // Should show in days

			// Test months (33 days)
			let monthResult = Duration.seconds(33 * 24 * 3600).formatted(Formatters.eta.locale(.init(identifier: "en_US")))
			#expect(monthResult == "33d")  // Should show in days
		}

		@Test("ETA formatter uses abbreviated units")
		func etaFormatterUsesAbbreviatedUnits() {
			let result = Duration.seconds(3661).formatted(Formatters.eta.locale(.init(identifier: "en_US")))  // 1 hour, 1 minute, 1 second
			#expect(result == "1h 1m 1s")
		}
	}

	// MARK: - Locale-Specific Formatting Tests

	@Suite("Locale-Specific Formatting Tests")
	struct LocaleSpecificFormattingTests {
		@Test("Byte formatter handles different locales")
		@MainActor
		func byteFormatterHandlesDifferentLocales() {
			Current.locale = Locale(identifier: "fr_FR")
			// Test that byte formatter works regardless of locale
			let result = 1024.formatted(Formatters.bytes.locale(.init(identifier: "fr_FR")))

			// Should contain the french version of kB
			#expect(result.contains("ko"))
		}

		@Test("Number formatting with decimal separators")
		func numberFormattingWithDecimalSeparators() {
			let result = 123.45.formatted(Formatters.float(precision: 2).locale(.init(identifier: "en_US")))

			// Should contain some form of decimal separator
			#expect(result == "123.45")
		}

		@Test("Percentage formatting with locale symbols")
		func percentageFormattingWithLocaleSymbols() {
			// Should contain percentage symbol
			#expect((0.5).formatted(Formatters.percentage(precision: 1).locale(.init(identifier: "en_US"))) == "50.0%")
		}
	}

	// MARK: - Edge Cases and Error Handling

	@Suite("Edge Cases and Error Handling")
	struct EdgeCasesAndErrorHandling {

		@Test("Handle NaN values")
		func handleNaNValues() {
			let nanResult = Double.nan.formatted(Formatters.float)
			#expect(nanResult == "NaN")
		}

		@Test("Handle negative byte counts")
		func handleNegativeByteCount() {
			let result = (-1024).formatted(Formatters.bytes)
			#expect(result == "-1 kB")  // Should handle gracefully
		}
	}
}
