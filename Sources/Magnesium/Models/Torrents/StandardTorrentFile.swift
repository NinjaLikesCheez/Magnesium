//
//  StandardTorrentFile.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//

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
			size: Formatters.bytes.string(fromByteCount: size),
			progress: Formatters.percentage.string(for: progress) ?? ""
		)
	}
}
