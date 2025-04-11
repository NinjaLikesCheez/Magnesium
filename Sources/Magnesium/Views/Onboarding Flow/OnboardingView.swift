import SwiftUI

struct OnboardingView: View {
	@State private var sheetDestination: ServerType?

	var body: some View {
		VStack(spacing: 20) {
			appIcon
			headlineText
			subtitleText
			addClientsButton
		}
		.sheet(item: $sheetDestination) { type in
			NavigationStack {
				switch type {
				case .deluge:
					DelugeServerSettingsView()
				case .qbittorrent:
					QBittorrentServerSettingsView()
				}
			}
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
				sheetDestination = type
			} label: {
				Text(type.rawValue)
					.fontWeight(.bold)
					.padding()
			}
			.foregroundStyle(.white)
			.frame(maxWidth: .infinity)
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
