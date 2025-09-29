import Common
import Logging
import SwiftUI
import Torrent

@main
struct MagnesiumApp: App {
	@State private var appState = AppState.resuming

	@State var session: Session
	@State var preferences: TorrentPreferences
	@State var torrentManager: TorrentManager

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
				//			logger.logLevel = .debug
			#endif
			return logger
		}

		self._preferences = .init(initialValue: TorrentPreferences(userDefaults: .standard, keychain: SystemKeychain()))
		self._session = .init(initialValue: Session(_preferences.wrappedValue))
		self._torrentManager = .init(initialValue: TorrentManager(session: _session.wrappedValue, preferences: _preferences.wrappedValue))
	}

	 var body: some Scene {
	 	WindowGroup {
	 		Group {
	 			switch appState {
	 			case .unauthenticated:
	 				OnboardingFlow(
	 					onboardingRouter: .init(),
	 					preferences: $preferences,
	 					session: $session
	 				)
	 			case .authenticated:
	 				TorrentsListFlow(
	 					torrentListRouter: .init(),
	 					torrentManager: $torrentManager,
	 					preferences: $preferences,
	 					session: $session
	 				)
	 			case .resuming:
	 				ProgressView()
	 					.containerRelativeFrame([.horizontal, .vertical])
	 			case .error(let error):
	 				ContentUnavailableView(
	 					"Error: \(error.localizedDescription)",
	 					image: "exclamationmark.triangle"
	 				)
	 			}
	 		}
	 		.task {
	 			guard session.server != nil else {
	 				appState = .unauthenticated
	 				return
	 			}

	 			appState = .authenticated
	 		}
	 		.onChange(of: session.server) { _, newValue in
	 			guard newValue != nil else {
	 				appState = .unauthenticated
	 				return
	 			}

	 			appState = .authenticated
	 		}
	 		.environment(preferences)
	 		.environment(session)
	 	}
	}
}
