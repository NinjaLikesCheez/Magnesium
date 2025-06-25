import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@State private var router = AppRouter()
	@State private var appState = AppState.resuming

	@State var session = Session()
	@State var preferences = AppPreferences(userDefaults: .standard)
	@State var torrentManager: TorrentManager? = nil

	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
			logger.logLevel = .debug
			#endif
			return logger
		}
		self._torrentManager = State(initialValue: TorrentManager(session: session))
	}

	var body: some Scene {
		WindowGroup {
			Group {
				switch appState {
				case .unauthenticated:
					OnboardingFlow(
						onboardingRouter: .init(router),
						preferences: $preferences,
						session: $session
					)
				case .authenticated:
					TorrentsListFlow(
						torrentListRouter: .init(router),
						torrentManager: .constant(torrentManager!),
						preferences: $preferences,
						session: $session
					)
//					NavigationStack(path: $router.path) {
//						TorrentsView()
//							.withAppDestinations()
//							.withAppSheets(router: $router, preferences: $preferences, session: $session)
//							.environment(TorrentManager(session: session))
//					}
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
			.environment(router)
			.environment(preferences)
			.environment(session)
		}
	}
}
