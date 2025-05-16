import SwiftUI

struct OnboardingView: View {
	@Environment(Router.self) var router

	var body: some View {
		VStack(spacing: 20) {
			appIcon
			headlineText
			subtitleText
			addClientsButton
		}
	}
	var appIcon: some View {
		Image("Icon")
			.resizable()
			.scaledToFit()
			.cornerRadius(15)
			.padding()
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

	var addClientsButton: some View {
		ForEach(ServerType.allCases) { type in 
			Button {
				router.push(.addServer(type))
			} label: {
				Text(type.rawValue)
					.fontWeight(.bold)
					.frame(maxWidth: .infinity)
					.padding()
			}
			.foregroundStyle(.white)
			.background(Color.accentColor)
			.cornerRadius(10)
			.padding(.horizontal)
		}
		.fixedSize(horizontal: false, vertical: true)
	}
}

#Preview {
	OnboardingView()
}
