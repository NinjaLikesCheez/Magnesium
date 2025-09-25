//
//  StandardTorrentFile.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//
import Common

public struct StandardTorrentFile: Equatable, Hashable, Identifiable {
	public var id: Int { index }

	public var index: Int
	public var name: String
	public var size: Int64
	public var progress: Float
	public var priority: StandardTorrentPriority

	public init(index: Int, name: String, size: Int64, progress: Float, priority: StandardTorrentPriority) {
		self.index = index
		self.name = name
		self.size = size
		self.progress = progress
		self.priority = priority
	}
}

extension StandardTorrentFile {
	public var localizedProgress: String {
		let size = self.size.formatted(Formatters.bytes)
		let progress = self.progress.formatted(Formatters.percentage)

		return "\(size) (\(progress))"
	}
}
