import Foundation

struct TorrentMapper {
	static func map(
		_ torrents: [StandardTorrent],
		query: String,
		sortOption: SortOption,
		filterOptions: FilterOptions
	) -> [StandardTorrent] {
		Self.sort(
			Self.filter(torrents, using: filterOptions, query: query),
			using: sortOption
		)
	}

	static func filter(_ values: [StandardTorrent], using filter: FilterOptions, query: String) -> [StandardTorrent] {
		var filtered = values

		if !filter.states.isEmpty {
			filtered = filtered.filter { value in
				filter.states.contains(value.state)
			}
		}

		if !filter.labels.isEmpty {
			filtered = filtered.filter { value in
				filter.labels.contains(value.label)
			}
		}

		if !query.isEmpty {
			let trimmed = (query as NSString).trimmingCharacters(in: CharacterSet.whitespaces)
			if !trimmed.isEmpty {
				filtered = filtered.filter { value in
					Self.search(needle: trimmed, haystack: value.name)
				}
			}
		}

		return filtered
	}

	private static func search(needle: String, haystack: String) -> Bool {
		let delimiters = CharacterSet([" ", ".", "-", "_"])
		let normalizedNeedle = needle.lowercased().components(separatedBy: delimiters).joined(separator: " ")
		let normalizedHaystack = haystack.lowercased().components(separatedBy: delimiters).joined(separator: " ")
		return normalizedHaystack.contains(normalizedNeedle)
	}

	static func sort(_ values: [StandardTorrent]) {

	}

	// swiftlint:disable:next cyclomatic_complexity
	private static func sort(
		_ torrents: [StandardTorrent],
		using sortOption: SortOption
	) -> [StandardTorrent] {
		let compare: (StandardTorrent, StandardTorrent) -> ComparisonResult
		switch sortOption.property {
		case .name:
			compare = { $0.name.compare($1.name, options: [.numeric, .caseInsensitive]) }
		case .dateAdded:
			compare = { $0.dateAdded.compare($1.dateAdded) }
		case .downloadSpeed:
			compare = {
				$0.downloadRate == $1.downloadRate
					? .orderedSame
					: $0.downloadRate < $1.downloadRate ? .orderedAscending : .orderedDescending
			}
		case .uploadSpeed:
			compare = {
				$0.uploadRate == $1.uploadRate
					? .orderedSame
					: $0.uploadRate < $1.uploadRate ? .orderedAscending : .orderedDescending
			}
		case .progress:
			compare = {
				$0.progress == $1.progress
					? .orderedSame
					: $0.progress < $1.progress ? .orderedAscending : .orderedDescending
			}
		}

		return torrents.sorted { torrent1, torrent2 -> Bool in
			switch compare(torrent1, torrent2) {
			case .orderedAscending:
				return sortOption.direction == .ascending
			case .orderedDescending:
				return sortOption.direction == .descending
			case .orderedSame:
				if sortOption.property != .name {
					let result = torrent1.name.compare(torrent2.name, options: [.numeric, .caseInsensitive])
					switch result {
					case .orderedAscending:
						return true
					case .orderedDescending:
						return false
					case .orderedSame:
						break
					}
				}

				return torrent1.hash < torrent2.hash
			}
		}
	}
}
