import Common
import CommonUI
import Observation
import SonarrSession
import SwiftUI
import SwiftUINavigation

public struct SonarrSettingsFlow: View {
	@State private var model = Model()

	let preferences: SonarrPreferences
	let session: SonarrSession

	public init(preferences: SonarrPreferences, session: SonarrSession) {
		self.preferences = preferences
		self.session = session
	}

	public var body: some View {
		@Bindable var model = model

		SonarrSettingsListView()
			.environment(model)
			.environment(preferences)
			.environment(session)
	}
}

extension SonarrSettingsFlow {
	@Observable
	final class Model {
		var destination: Destination?
		var error: Error?

		init() {}

		/// Only one screen to push to — unlike Torrent's Settings, there's no "pick a server type"
		/// step, since Sonarr has exactly one backend.
		@CasePathable
		enum Destination: Hashable {
			case addOrEditServer
		}

		@CasePathable
		enum Error: Hashable, Identifiable {
			case preferences(SonarrPreferences.Error)
			case addServerError(SonarrServerSettingsError)

			var id: Self { self }
		}
	}
}

extension SonarrSettingsFlow.Model.Error: VisualError {
	var title: String {
		switch self {
		case let .preferences(error):
			error.title
		case let .addServerError(error):
			error.title
		}
	}

	var systemName: String {
		switch self {
		case let .preferences(error):
			error.systemName
		case let .addServerError(error):
			error.systemName
		}
	}

	var subtitle: String {
		switch self {
		case let .preferences(error):
			error.subtitle
		case let .addServerError(error):
			error.subtitle
		}
	}
}
