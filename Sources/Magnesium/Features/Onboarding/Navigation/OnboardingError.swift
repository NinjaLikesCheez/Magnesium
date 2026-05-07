import Router
import SwiftUI
import CommonUI

enum OnboardingError: RoutableError {
	var id: Self { fatalError("Not yet implemented") }
}

struct OnboardingErrorModifier: RoutableErrorViewModifier {
	@Binding var router: OnboardingRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				default: fatalError("Not yet implemented")
				}
			}
	}
}

extension View {
	func withOnboardingErrors(router: Binding<OnboardingRouter>) -> some View {
		modifier(OnboardingErrorModifier(router: router))
	}
}
