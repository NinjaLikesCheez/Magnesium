import CommonUI
import SonarrSession
import SwiftUI
import SwiftUINavigation

/// The Onboarding feature's entry point view.
///
/// - Important: This view does not provide its own `NavigationStack` — it relies on
///   `.navigationDestination(item:)`, which requires an enclosing stack to push into. Callers
///   must wrap this view in a `NavigationStack`.
public struct SonarrOnboardingFlow: View {
	@State public var model: Model = .init()

	let preferences: SonarrPreferences
	let session: SonarrSession

	public init(preferences: SonarrPreferences, session: SonarrSession) {
		self.preferences = preferences
		self.session = session
	}

	public var body: some View {
		@Bindable var model = model

		SonarrOnboardingView()
			.navigationDestination(item: $model.destination.addServer) { _ in
				AddSonarrServerView(onError: { model.error = .addServerError($0) })
					.environment(model)
					.environment(preferences)
			}
			.panel(item: $model.error.addServerError) { error in
				ErrorPanelCard(
					error: error,
					primaryButtonAction: { model.error = nil }
				)
			}
			.environment(model)
			.environment(preferences)
			.environment(session)
	}
}

extension SonarrOnboardingFlow {
	@Observable
	public final class Model {
		public var destination: Destination?
		public var error: Error?

		public init() {}

		@CasePathable
		public enum Destination: Hashable {
			case addServer
		}

		@CasePathable
		public enum Error: Hashable {
			case addServerError(SonarrServerSettingsError)
		}
	}
}
