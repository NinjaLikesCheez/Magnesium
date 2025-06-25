import SwiftUI
import Logging

@main
struct MagnesiumApp: App {
	@State private var router = AppRouter()
	@State private var appState = AppState.resuming

	@State var session = Session()
	@State var preferences = AppPreferences(userDefaults: .standard)


	init() {
		LoggingSystem.bootstrap { label in
			var logger = StreamLogHandler.standardOutput(label: label)
			#if DEBUG
			logger.logLevel = .debug
			#endif
			return logger
		}
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
				case .authenticated(let session):
					NavigationStack(path: $router.path) {
						TorrentsView()
							.withAppDestinations()
							.withAppSheets(router: $router, preferences: $preferences, session: $session)
							.environment(TorrentManager(session: session))
					}
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

				appState = .authenticated(session: session)
			}
			.onChange(of: session.server) { _, newValue in
				guard newValue != nil else {
					appState = .unauthenticated
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
