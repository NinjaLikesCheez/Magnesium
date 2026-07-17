import Common
import SentrySwift

import Logging
import SwiftUI
import TorrentUI

@main
struct MagnesiumApp: App {
	@State var appModules: AppModules = .shared

	init() {
		SentrySDK.start { options in
			options.dsn = "https://83674bc4dc849f66d4a7101a558b20b4@o1151234.ingest.us.sentry.io/4511251402719232"

			// Adds IP for users.
			// For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
			options.sendDefaultPii = true

			// Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
			// We recommend adjusting this value in production.
			options.tracesSampleRate = 1.0

			// Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
			options.configureProfiling = {
				$0.sessionSampleRate = 1.0 // We recommend adjusting this value in production.
				$0.lifecycle = .trace
			}

			// Uncomment the following lines to add more data to your events
			 options.attachScreenshot = true // This adds a screenshot to the error events
			 options.attachViewHierarchy = true // This adds the view hierarchy to the error events

			// Enable experimental logging features
			options.enableLogs = true

			options.enableAutoPerformanceTracing = true

#if os(iOS)
			// Let users report feedback by shaking the device.
			options.configureUserFeedback = { config in
				config.useShakeGesture = true
			}
#endif
		}

		LoggingSystem.bootstrap { label in

#if DEBUG
			var logger = StreamLogHandler.standardOutput(label: label)
			logger.logLevel = .debug
#else
			let logger = StreamLogHandler.standardOutput(label: label)
#endif
			return logger
		}
	}

	var body: some Scene {
		WindowGroup {
			AppView()
				.environment(appModules)
				.sentryTrace()
		}
	}
}
