//
//  TorrentSettingsFlow.swift
//  Torrent
//
//  Created by ninji on 06/10/2025.
//

import CommonUI
import Observation
import SwiftUI
import SwiftUINavigation

public struct TorrentSettingsFlow: View {
	@State private var model = TorrentSettingsModel()

	let preferences: TorrentPreferences
	let session: TorrentSession

	public init(preferences: TorrentPreferences, session: TorrentSession) {
		self.preferences = preferences
		self.session = session
	}

	public var body: some View {
		@Bindable var model = model

		TorrentSettingsListView()
			.environment(model)
			.environment(preferences)
			.environment(session)
	}
}

extension TorrentSettingsFlow {
	@Observable
	final class TorrentSettingsModel {
		var destination: Destination?

		init() {}

		/// Stack-navigation targets for the Settings feature. Genuinely multi-level: the list can
		/// push `addAServer`, and `addAServer` itself pushes `addNewServer`.
		@CasePathable
		enum Destination: Hashable {
			/// Navigate to edit an existing server's configuration
			case editServer(TorrentServer)

			/// Navigate to the server selection screen where users can choose which type of server to add
			case addAServer
		}
	}
}
