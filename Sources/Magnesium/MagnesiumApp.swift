import SwiftUI

@main
struct MagnesiumApp: App {
	@State private var session = Session()

	var body: some Scene {
		WindowGroup {
			if session.server == nil {
				OnboardingView()
					.environment(session)
			} else {
				TorrentListView()
					.environment(session)
			}
		}
	}
}
