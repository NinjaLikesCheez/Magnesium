import Common
import SwiftUI

struct SonarrOnboardingView: View {
	@Environment(SonarrOnboardingFlow.Model.self) var model

	var body: some View {
		VStack(spacing: 16) {
			Image(systemName: "tv")
				.font(.system(size: 60))
				.foregroundStyle(.secondary)

			Text("Sonarr")
				.font(.largeTitle)
				.fontWeight(.bold)

			Text("Connect to your Sonarr instance to manage your TV series")
				.font(.subheadline)
				.foregroundStyle(.secondary)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 40)

			Button {
				model.destination = .addServer
			} label: {
				Text("Add Server")
					.fontWeight(.bold)
					.frame(maxWidth: .infinity)
					.padding()
			}
			.backport.glassButtonStyle()
			.buttonBorderShape(.capsule)
			.padding(.horizontal, 40)
			.padding(.top, 8)
		}
		.frame(maxHeight: .infinity)
	}
}
