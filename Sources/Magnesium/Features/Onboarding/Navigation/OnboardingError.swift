import Router
import CommonUI
import SwiftUI

enum OnboardingError: RoutableError {
	var id: Self { self }

	case addServerError(ServerSettingsError)
}

struct OnboardingErrorModifier: RoutableErrorViewModifier {
	@Binding var router: OnboardingRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				case let .addServerError(error):
					ErrorPanelCard(
						error: error,
						primaryButtonAction: router.dismissError
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
