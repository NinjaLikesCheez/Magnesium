import Testing
import Foundation
@testable import Magnesium

@Suite("Formatters Tests")
struct FormattersTests {
    
    // MARK: - Byte Count Formatting Tests
    
    @Suite("Byte Count Formatting Tests")
    struct ByteCountFormattingTests {
        
        @Test("Format bytes with various sizes")
        func formatBytesWithVariousSizes() {
            // Test small values
            #expect(Formatters.bytes.string(fromByteCount: 0) == "Zero KB")
            #expect(Formatters.bytes.string(fromByteCount: 512) == "0.5 KB")
            #expect(Formatters.bytes.string(fromByteCount: 1024) == "1.0 KB")
            
            // Test KB range
            #expect(Formatters.bytes.string(fromByteCount: 2048) == "2.0 KB")
            #expect(Formatters.bytes.string(fromByteCount: 1536) == "1.5 KB")
            
            // Test MB range
            #expect(Formatters.bytes.string(fromByteCount: 1024 * 1024) == "1.0 MB")
            #expect(Formatters.bytes.string(fromByteCount: 1024 * 1024 * 2) == "2.0 MB")
            #expect(Formatters.bytes.string(fromByteCount: 1024 * 1024 + 512 * 1024) == "1.5 MB")
            
            // Test GB range
            #expect(Formatters.bytes.string(fromByteCount: 1024 * 1024 * 1024) == "1.0 GB")
            #expect(Formatters.bytes.string(fromByteCount: Int64(1024) * 1024 * 1024 * 5) == "5.0 GB")
            
            // Test TB range
            #expect(Formatters.bytes.string(fromByteCount: Int64(1024) * 1024 * 1024 * 1024) == "1.0 TB")
        }
        
        @Test("Format bytes with binary units")
        func formatBytesWithBinaryUnits() {
            // Verify binary (1024-based) counting is used
            let oneMB = 1024 * 1024
            let result = Formatters.bytes.string(fromByteCount: Int64(oneMB))
            #expect(result == "1.0 MB")
            
            // Test that decimal (1000-based) would be different
            let oneDecimalMB = 1000 * 1000
            let decimalResult = Formatters.bytes.string(fromByteCount: Int64(oneDecimalMB))
            #expect(decimalResult != "1.0 MB") // Should be less than 1.0 MB in binary
        }
        
        @Test("Format bytes excludes byte unit")
        func formatBytesExcludesByteUnit() {
            // Verify that bytes unit is not used (minimum is KB)
            let result = Formatters.bytes.string(fromByteCount: 100)
            #expect(!result.contains("bytes"))
            #expect(!result.contains("B ")) // Space after B would indicate bytes unit
        }
        
        @Test("Format bytes with zero padding")
        func formatBytesWithZeroPadding() {
            // Test that fraction digits are zero-padded
            let result = Formatters.bytes.string(fromByteCount: 1024)
            #expect(result.contains(".0")) // Should show .0 for whole numbers
        }
        
        @Test("Format large byte values")
        func formatLargeByteValues() {
            // Test very large values
            let petabyte = Int64(1024) * 1024 * 1024 * 1024 * 1024
            let result = Formatters.bytes.string(fromByteCount: petabyte)
            #expect(result.contains("PB") || result.contains("TB")) // Should handle large values
        }
    }
    
    // MARK: - Percentage Formatting Tests
    
    @Suite("Percentage Formatting Tests")
    struct PercentageFormattingTests {
        
        @Test("Format percentage with default precision")
        func formatPercentageWithDefaultPrecision() {
            let formatter = Formatters.percentage
            
            #expect(formatter.string(from: 0.0) == "0%")
            #expect(formatter.string(from: 0.5) == "50%")
            #expect(formatter.string(from: 1.0) == "100%")
            #expect(formatter.string(from: 0.123) == "12%")
        }
        
        @Test("Format percentage with custom precision")
        func formatPercentageWithCustomPrecision() {
            let formatter1 = Formatters.percentage(precision: 1)
            let formatter2 = Formatters.percentage(precision: 2)
            
            // Test 1 decimal place
            #expect(formatter1.string(from: 0.123) == "12.3%")
            #expect(formatter1.string(from: 0.1234) == "12.3%")
            
            // Test 2 decimal places
            #expect(formatter2.string(from: 0.123) == "12.30%")
            #expect(formatter2.string(from: 0.1234) == "12.34%")
        }
        
        @Test("Format percentage with various precision levels")
        func formatPercentageWithVariousPrecisionLevels() {
            let value = 0.123456
            
            let formatter0 = Formatters.percentage(precision: 0)
            let formatter1 = Formatters.percentage(precision: 1)
            let formatter2 = Formatters.percentage(precision: 2)
            let formatter3 = Formatters.percentage(precision: 3)
            
            #expect(formatter0.string(from: value) == "12%")
            #expect(formatter1.string(from: value) == "12.3%")
            #expect(formatter2.string(from: value) == "12.35%")
            #expect(formatter3.string(from: value) == "12.346%")
        }
        
        @Test("Format percentage edge cases")
        func formatPercentageEdgeCases() {
            let formatter = Formatters.percentage(precision: 2)
            
            // Test edge values
            #expect(formatter.string(from: 0.0) == "0.00%")
            #expect(formatter.string(from: 1.0) == "100.00%")
            
            // Test values over 100%
            #expect(formatter.string(from: 1.5) == "150.00%")
            #expect(formatter.string(from: 2.0) == "200.00%")
            
            // Test very small values
            #expect(formatter.string(from: 0.001) == "0.10%")
        }
        
        @Test("Percentage formatter caching")
        func percentageFormatterCaching() {
            // Test that formatters are cached and reused
            let formatter1a = Formatters.percentage(precision: 1)
            let formatter1b = Formatters.percentage(precision: 1)
            let formatter2 = Formatters.percentage(precision: 2)
            
            // Same precision should return same instance
            #expect(formatter1a === formatter1b)
            
            // Different precision should return different instance
            #expect(formatter1a !== formatter2)
        }
    }
    
    // MARK: - Number Formatting Tests
    
    @Suite("Number Formatting Tests")
    struct NumberFormattingTests {
        
        @Test("Format number with default precision")
        func formatNumberWithDefaultPrecision() {
            let formatter = Formatters.number
            
            #expect(formatter.string(from: 0) == "0")
            #expect(formatter.string(from: 123) == "123")
            #expect(formatter.string(from: 123.456) == "123")
        }
        
        @Test("Format number with custom precision")
        func formatNumberWithCustomPrecision() {
            let formatter1 = Formatters.number(precision: 1)
            let formatter2 = Formatters.number(precision: 2)
            
            // Test 1 decimal place
            #expect(formatter1.string(from: 123.456) == "123.5")
            #expect(formatter1.string(from: 123) == "123.0")
            
            // Test 2 decimal places
            #expect(formatter2.string(from: 123.456) == "123.46")
            #expect(formatter2.string(from: 123) == "123.00")
        }
        
        @Test("Format number with various precision levels")
        func formatNumberWithVariousPrecisionLevels() {
            let value = 123.456789
            
            let formatter0 = Formatters.number(precision: 0)
            let formatter1 = Formatters.number(precision: 1)
            let formatter2 = Formatters.number(precision: 2)
            let formatter3 = Formatters.number(precision: 3)
            
            #expect(formatter0.string(from: value) == "123")
            #expect(formatter1.string(from: value) == "123.5")
            #expect(formatter2.string(from: value) == "123.46")
            #expect(formatter3.string(from: value) == "123.457")
        }
        
        @Test("Number formatter caching")
        func numberFormatterCaching() {
            // Test that formatters are cached and reused
            let formatter1a = Formatters.number(precision: 1)
            let formatter1b = Formatters.number(precision: 1)
            let formatter2 = Formatters.number(precision: 2)
            
            // Same precision should return same instance
            #expect(formatter1a === formatter1b)
            
            // Different precision should return different instance
            #expect(formatter1a !== formatter2)
        }
        
        @Test("Format negative numbers")
        func formatNegativeNumbers() {
            let formatter = Formatters.number(precision: 2)
            
            #expect(formatter.string(from: -123.456) == "-123.46")
            #expect(formatter.string(from: -0.1) == "-0.10")
        }
    }
    
    // MARK: - ETA Formatting Tests
    
    @Suite("ETA Formatting Tests")
    struct ETAFormattingTests {
        
        @Test("Format ETA with various time intervals")
        func formatETAWithVariousTimeIntervals() {
            let formatter = Formatters.eta
            
            // Test seconds
            #expect(formatter.string(from: 30) == "30 sec")
            #expect(formatter.string(from: 59) == "59 sec")
            
            // Test minutes
            #expect(formatter.string(from: 60) == "1 min")
            #expect(formatter.string(from: 90) == "1 min, 30 sec")
            #expect(formatter.string(from: 3600 - 1) == "59 min, 59 sec")
            
            // Test hours
            #expect(formatter.string(from: 3600) == "1 hr")
            #expect(formatter.string(from: 3660) == "1 hr, 1 min")
            #expect(formatter.string(from: 7200) == "2 hr")
            
            // Test days
            #expect(formatter.string(from: 86400) == "1 day")
            #expect(formatter.string(from: 90000) == "1 day, 1 hr")
        }
        
        @Test("Format ETA with zero and negative values")
        func formatETAWithZeroAndNegativeValues() {
            let formatter = Formatters.eta
            
            // Test zero
            let zeroResult = formatter.string(from: 0)
            #expect(zeroResult != nil) // Should handle zero gracefully
            
            // Test negative (should handle gracefully)
            let negativeResult = formatter.string(from: -100)
            #expect(negativeResult != nil) // Should not crash
        }
        
        @Test("Format ETA with large time intervals")
        func formatETAWithLargeTimeIntervals() {
            let formatter = Formatters.eta
            
            // Test weeks (7 days)
            let oneWeek = 7 * 24 * 3600
            let result = formatter.string(from: TimeInterval(oneWeek))
            #expect(result?.contains("day") == true) // Should show in days
            
            // Test months (30 days)
            let oneMonth = 30 * 24 * 3600
            let monthResult = formatter.string(from: TimeInterval(oneMonth))
            #expect(monthResult?.contains("day") == true) // Should show in days
        }
        
        @Test("ETA formatter uses abbreviated units")
        func etaFormatterUsesAbbreviatedUnits() {
            let formatter = Formatters.eta
            
            let result = formatter.string(from: 3661) // 1 hour, 1 minute, 1 second
            
            // Should use abbreviated forms
            #expect(result?.contains("hr") == true || result?.contains("h") == true)
            #expect(result?.contains("min") == true || result?.contains("m") == true)
            #expect(result?.contains("sec") == true || result?.contains("s") == true)
            
            // Should not use full forms
            #expect(result?.contains("hour") == false)
            #expect(result?.contains("minute") == false)
            #expect(result?.contains("second") == false)
        }
    }
    
    // MARK: - Locale-Specific Formatting Tests
    
    @Suite("Locale-Specific Formatting Tests")
    struct LocaleSpecificFormattingTests {
        
        @Test("Formatters use current locale")
        func formattersUseCurrentLocale() {
            // Test that formatters respect the Current.locale setting
            let numberFormatter = Formatters.number(precision: 2)
            let percentageFormatter = Formatters.percentage(precision: 2)
            
            // Verify locale is set
            #expect(numberFormatter.locale == Current.locale)
            #expect(percentageFormatter.locale == Current.locale)
        }
        
        @Test("ETA formatter uses current calendar")
        func etaFormatterUsesCurrentCalendar() {
            let etaFormatter = Formatters.eta
            
            // Verify calendar is set
            #expect(etaFormatter.calendar == Current.calendar)
        }
        
        @Test("Byte formatter handles different locales")
        func byteFormatterHandlesDifferentLocales() {
            // Test that byte formatter works regardless of locale
            let result = Formatters.bytes.string(fromByteCount: 1024)
            
            // Should contain some form of KB/MB designation
            #expect(result.contains("KB") || result.contains("MB") || result.contains("kB"))
        }
        
        @Test("Number formatting with decimal separators")
        func numberFormattingWithDecimalSeparators() {
            let formatter = Formatters.number(precision: 2)
            let result = formatter.string(from: 123.45)
            
            // Should contain some form of decimal separator
            #expect(result?.contains(".") == true || result?.contains(",") == true)
        }
        
        @Test("Percentage formatting with locale symbols")
        func percentageFormattingWithLocaleSymbols() {
            let formatter = Formatters.percentage(precision: 1)
            let result = formatter.string(from: 0.5)
            
            // Should contain percentage symbol
            #expect(result?.contains("%") == true)
        }
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Suite("Edge Cases and Error Handling")
    struct EdgeCasesAndErrorHandling {
        
        @Test("Handle extreme values gracefully")
        func handleExtremeValuesGracefully() {
            // Test very large numbers
            let largeNumber = Double.greatestFiniteMagnitude
            let numberResult = Formatters.number.string(from: largeNumber)
            #expect(numberResult != nil)
            
            // Test very small numbers
            let smallNumber = Double.leastNormalMagnitude
            let smallResult = Formatters.number.string(from: smallNumber)
            #expect(smallResult != nil)
            
            // Test infinity
            let infinityResult = Formatters.number.string(from: Double.infinity)
            #expect(infinityResult != nil)
        }
        
        @Test("Handle NaN values")
        func handleNaNValues() {
            let nanResult = Formatters.number.string(from: Double.nan)
            #expect(nanResult != nil) // Should not crash
        }
        
        @Test("Handle negative byte counts")
        func handleNegativeByteCount() {
            let result = Formatters.bytes.string(fromByteCount: -1024)
            #expect(result != nil) // Should handle gracefully
        }
        
        @Test("Handle extreme time intervals")
        func handleExtremeTimeIntervals() {
            // Test very large time interval
            let largeInterval = TimeInterval.greatestFiniteMagnitude
            let result = Formatters.eta.string(from: largeInterval)
            #expect(result != nil) // Should not crash
            
            // Test infinity
            let infinityResult = Formatters.eta.string(from: TimeInterval.infinity)
            #expect(infinityResult != nil) // Should not crash
        }
    }
}