import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@State private var router = AppRouter()
	@State private var appState = AppState.resuming

	@State var session = Session()
	@State var preferences = AppPreferences(userDefaults: .standard)

//	@State private var torrentManager: TorrentManager

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
//			logger.logLevel = .debug
			#endif
			return logger
		}
//		_torrentManager = State(wrappedValue: TorrentManager(session: session))
	}

	var body: some Scene {
		WindowGroup {
			NavigationStack(path: $router.path) {
				Group {
					switch appState {
					case .unauthenticated:
						OnboardingView()
					case .authenticated(let session):
						TorrentsView()
							.environment(TorrentManager(session: session))
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
				.withAppDestinations()
				.withAppSheets(router: $router, preferences: $preferences, session: $session)
			}
			.task {
				guard session.server != nil else {
					appState = .unauthenticated
					return
				}

				appState = .authenticated(session: session)
			}
			.onChange(of: session.server) { _, newValue in
				guard newValue != nil else {
					return
				}

				appState = .authenticated(session: session)
			}
			.environment(router)
			.environment(preferences)
			.environment(session)
		}
	}
}
