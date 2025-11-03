import SwiftUI
import Common
import TorrentUI

public struct OnboardingListView: View {
	@Environment(OnboardingRouter.self) var router

	public var body: some View {
		List {
			Text("Onboarding")
		}
		.navigationTitle("Onboarding")
	}
}

#Preview {
	OnboardingFlow(router: .init())
}
