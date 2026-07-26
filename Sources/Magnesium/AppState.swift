//
//  AppState.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//
import MagnesiumModule
import Observation
import SonarrUI
import TorrentUI

enum AppState: Sendable {
	case unboarded
	case onboarded
	case resuming
	case error(Error)
}

@MainActor
@Observable
class AppModules {
	@MainActor
	enum ModuleType: Hashable, Equatable, @MainActor Identifiable {
		case torrent(TorrentModule)
		case sonarr(SonarrModule)

		var id: String {
			switch self {
			case let .torrent(module):
				module.name
			case let .sonarr(module):
				module.name
			}
		}

		var rawValue: any MagnesiumFeatureModule {
			switch self {
			case let .torrent(module):
				module
			case let .sonarr(module):
				module
			}
		}
	}

	static var shared: AppModules = .init()

	let modules: [ModuleType]

	let torrent: TorrentModule = .init()
	let sonarr: SonarrModule = .init()

	private init() {
		modules = [.torrent(torrent), .sonarr(sonarr)]
	}
}

extension AppModules: @MainActor Sequence {
	// Sequence conformance
	typealias Element = ModuleType

	func makeIterator() -> IndexingIterator<[Element]> {
		modules.makeIterator()
	}

	// Common collection conveniences
	var count: Int { modules.count }

	subscript(index: Int) -> Element { modules[index] }
}
