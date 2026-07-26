import Common
import CommonUI
import SonarrCore
import SonarrSession
import SwiftUI
import SwiftUINavigation

public struct SonarrSeriesListFlow: View {
	@State public var model: Model = .init()

	let session: SonarrSession
	let preferences: SonarrPreferences

	public init(session: SonarrSession, preferences: SonarrPreferences) {
		self.session = session
		self.preferences = preferences
	}

	public var body: some View {
		@Bindable var model = model

		SonarrSeriesListView()
			.panel(item: $model.error.clientError) { error in
				ErrorPanelCard(
					error: error,
					primaryButtonAction: { model.error = nil }
				)
			}
			.environment(model)
			.environment(session)
			.environment(preferences)
	}
}

extension SonarrSeriesListFlow {
	@Observable
	public final class Model {
		public var destination: Destination?
		public var error: Error?

		public init() {}

		@CasePathable
		public enum Destination: Hashable {
			case detail(StandardSeries)
		}

		@CasePathable
		public enum Error: Hashable {
			case clientError(SonarrClientError)
		}
	}
}
