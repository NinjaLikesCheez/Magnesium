import Router
import SwiftUI

enum OnboardingError: RoutableError {
	var id: Self { self }

	case addServerError
}

struct OnboardingErrorModifier: RoutableErrorViewModifier {
	@Binding var router: OnboardingRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case .addServerError:
					// TODO: Make a 'Panel Information View'
					PanelCard(
						title: "Couldn't Add Server",
						systemImage: "server.rack",
						subtitle: ""
					)
				}
			}
	}
}

extension View {
	func withOnboardingErrors(router: Binding<OnboardingRouter>) -> some View {
		modifier(OnboardingErrorModifier(router: router))
	}
}
