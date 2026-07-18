import Foundation

extension L10n {
	enum File {
		static func progress(size: String, progress: String) -> String {
			let format = NSLocalizedString("file.progress", comment: "{size} ({percentage})")
			return .localizedStringWithFormat(format, size, progress)
		}

		static func count(_ count: Int) -> String {
			let format = NSLocalizedString("file.count", comment: "{number} Files")
			return .localizedStringWithFormat(format, count)
		}
	}
}
