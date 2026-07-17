//
//  TorrentOnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import CommonUI
import SwiftUI
import SwiftUINavigation

public struct TorrentOnboardingFlow: View {
	@State public var model: Model = .init()

	let preferences: TorrentPreferences
	let session: TorrentSession

	public init(preferences: TorrentPreferences, session: TorrentSession) {
		self.preferences = preferences
		self.session = session
	}

	public var body: some View {
		@Bindable var model = model

		NavigationStack {
			TorrentOnboardingView()
				.navigationDestination(item: $model.destination.addNewServer) { $type in
					switch type {
					case .deluge:
						OnboardingAddDelugeServerView()
					case .qbittorrent:
						OnboardingAddQBittorrentServerView()
					}
				}
				.sheet(item: $model.sheet.addNewServer) { $type in
					NavigationStack {
						switch type {
						case .deluge:
							OnboardingAddDelugeServerView()
						case .qbittorrent:
							OnboardingAddQBittorrentServerView()
						}
					}
				}
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

extension TorrentOnboardingFlow {
	/// Navigation model for the Onboarding feature.
	///
	/// Handles navigation during the initial app setup process for server
	/// configuration.
	@Observable
	public final class Model {
		public var destination: Destination?
		public var sheet: Sheet?
		public var error: Error?

		public init() {}

		/// Stack-navigation targets for the Onboarding feature.
		@CasePathable
		public enum Destination: Hashable {
			/// Add a new server of a specific type
			case addNewServer(TorrentServerType)
		}

		/// Modal presentations for the Onboarding feature.
		@CasePathable
		public enum Sheet: Hashable {
			/// Add a new server of a specific type
			case addNewServer(TorrentServerType)
		}

		/// Modal error presentations for the Onboarding feature.
		@CasePathable
		public enum Error: Hashable {
			case addServerError(ServerSettingsError)
		}
	}
}
