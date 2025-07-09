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
					VStack(spacing: 24) {
						VStack(spacing: 32) {
							Text("Couldn't Add Server")
								.font(.title)
								.foregroundColor(Color(.darkGray))

							Image(systemName: "exclamationmark")
								.font(.system(size: 100))
								.foregroundColor(Color(.lightGray))

//							Text("Do you want to share the Wi-Fi password for \"Home\" with Pita Bread?")
//								.multilineTextAlignment(.center)
						}

						Button(
							action: { router.dismissError() },
							label: {
								Text("Done")
									.frame(maxWidth: .infinity)
							}
						)
						.buttonStyle(.borderedProminent)
						.controlSize(.large)
					}
				}
			}
	}
}

extension View {
	func withOnboardingErrors(router: Binding<OnboardingRouter>) -> some View {
		modifier(OnboardingErrorModifier(router: router))
	}
}
