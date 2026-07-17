//
//  TorrentOnboardingFlow.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import CommonUI
import SwiftUI
import SwiftUINavigation

/// The Onboarding feature's entry point view.
///
/// - Important: This view does not provide its own `NavigationStack` — it relies on
///   `.navigationDestination(item:)`, which requires an enclosing stack to push into.
///   Callers must wrap this view in a `NavigationStack` (see `AppView`'s `.unboarded` case for
///   the app-level example, or `TorrentsListFlow`'s caller for the same convention applied to
///   the `entry` flow).
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

		TorrentOnboardingView()
			.navigationDestination(item: $model.destination.addNewServer) { $type in
				destinationContent(for: type)
			}
			.sheet(item: $model.sheet.addNewServer) { $type in
				NavigationStack {
					destinationContent(for: type)
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

	/// Pushed/sheeted destination content for a given server type.
	///
	/// - Important: Environment values must be injected here, on the destination content itself,
	///   rather than relying on inheritance from `body`'s outer `.environment(...)` calls.
	///   `.navigationDestination`/`.sheet` splice their pushed content in at the enclosing
	///   `NavigationStack`, not at the tree position where the modifier was applied, so ancestor
	///   environment values set below that stack are not guaranteed to reach the pushed content.
	@ViewBuilder
	private func destinationContent(for type: TorrentServerType) -> some View {
		switch type {
		case .deluge:
			OnboardingAddDelugeServerView()
				.environment(model)
				.environment(preferences)
				.environment(session)
		case .qbittorrent:
			OnboardingAddQBittorrentServerView()
				.environment(model)
				.environment(preferences)
				.environment(session)
		}
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
