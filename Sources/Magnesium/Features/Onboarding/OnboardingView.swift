import SwiftUI

struct OnboardingView: View {
	@Environment(OnboardingRouter.self) var router
	@Environment(\.horizontalSizeClass) var horizontalSizeClass

	var body: some View {
		VStack {
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
			.padding([.horizontal, .top], 50)
	}

	var headlineText: some View {
		AnimatedMeshGradientView()
			.mask {
				Text("Magnesium")
					.font(.system(size: 50))
					.fontWeight(.bold)
			}
	}

	var subtitleText: some View {
		Text("To start, add your first torrent client")
			.font(.subheadline)
			.foregroundStyle(.secondary)
	}

	var addClientsButton: some View {
		GeometryReader { reader in
			VStack {
				ForEach(ServerType.allCases) { type in
					if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
						Button {
							if horizontalSizeClass == .compact {
								router.push(.addNewServer(type))
							} else {
								// On larger screens, a sheet looks better
								router.presentSheet(.addNewServer(type))
							}
						} label: {
							Text(type.rawValue)
								.fontWeight(.bold)
								.frame(maxWidth: .infinity)
								.padding()
						}
						.buttonStyle(.glass)
						.buttonBorderShape(.capsule)
						//					.padding(.vertical, 10)
						.frame(maxWidth: reader.size.width * 0.5)
					} else {
						Button {
							if horizontalSizeClass == .compact {
								router.push(.addNewServer(type))
							} else {
								// On larger screens, a sheet looks better
								router.presentSheet(.addNewServer(type))
							}
						} label: {
							Text(type.rawValue)
								.fontWeight(.bold)
								.frame(maxWidth: .infinity)
								.padding()
						}
						.buttonBorderShape(.capsule)
						//					.padding(.vertical, 10)
						.frame(maxWidth: reader.size.width * 0.5)
					}
				}
			}
			.frame(width: reader.size.width, alignment: .center)
		}
	}
}

#Preview {
	OnboardingView()
}
