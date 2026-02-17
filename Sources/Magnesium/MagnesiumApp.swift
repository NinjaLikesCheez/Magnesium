import Common
import Logging
import SwiftUI
import TorrentUI

@main
struct MagnesiumApp: App {
	@State var appModules: AppModules = .shared

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
#if DEBUG
//			logger.logLevel = .debug
#endif
			return logger
		}
	}

	var body: some Scene {
		WindowGroup {
			AppView()
				.environment(appModules)
		}
	}
}
