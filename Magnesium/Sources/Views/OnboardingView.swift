import SwiftUI

struct OnboardingView: View {
	@State private var isShowingAddServerView = false

	var body: some View {
		VStack(spacing: 20) {
			appIcon
			headlineText
			subtitleText
			addClientButton
		}
		.sheet(isPresented: $isShowingAddServerView) {
			AddServerView()
				.interactiveDismissDisabled()
		}
	}
	var appIcon: some View {
		Image("AppIconAsset")
			.resizable()
			.scaledToFit()
			.frame(
				minWidth: 200,
				maxWidth: 500,
				minHeight: 200,
				maxHeight: 500
			)
	}

	var headlineText: some View {
		Text("Welcome to Magnesium!")
			.font(.largeTitle)
			.fontWeight(.bold)
	}

	var subtitleText: some View {
		Text("To start, add your first torrent client")
			.font(.subheadline)
			.foregroundStyle(.secondary)
	}

	var addClientButton: some View {
		Button {
			isShowingAddServerView = true
		} label: {
			Text("Add Client")
				.fontWeight(.bold)
				.padding()
		}
		.foregroundStyle(.white)
		.background(Color.accentColor)
		.cornerRadius(10)
		.padding()
	}
}

#Preview {
	OnboardingView()
}
