//
//  StandardTorrentFile.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//
import Common

struct StandardTorrentFile: Equatable, Hashable, Identifiable {
	var id: Int { index }

	var index: Int
	var name: String
	var size: Int64
	var progress: Float
	var priority: TorrentPriority
}

extension StandardTorrentFile {
	var localizedProgress: String {
		L10n.File.progress(
			size: size.formatted(Formatters.bytes),
			progress: progress.formatted(Formatters.percentage)
		)
	}
}
