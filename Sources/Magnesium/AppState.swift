//
//  AppState.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//
import TorrentUI
import Observation
import MagnesiumModule

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

		var id: String {
			switch self {
			case let .torrent(module):
				module.name
			}
		}

		var rawValue: any MagnesiumFeatureModule {
			switch self {
			case let .torrent(module):
				module
			}
		}
	}

	static var shared: AppModules = .init()

	let modules: [ModuleType]

	let torrent: TorrentModule = .init()

	private init() {
		modules = [.torrent(torrent)]
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
