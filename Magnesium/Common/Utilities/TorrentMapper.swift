import Combine
import Foundation
import Preferences

final class TorrentMapper: ValueMapper<String, StandardTorrent> {
    init(query: CurrentValueSubject<String?, Never>) {
        let sortOption = Current.preferences.valuePublisher(for: .sortOption)
        let filterOptions = Current.preferences.valuePublisher(for: .filterOptions)
        let filter = Publishers.CombineLatest3(sortOption, filterOptions, query)
            .map { sort, filter, query -> FilterFunction in
                // swiftformat:disable:next redundantReturn
                return { subjects in
                    var filtered = subjects

                    if let state = filter.state {
                        filtered = filtered.filter { subject in
                            subject.value.state == state
                        }
                    }

                    if let label = filter.label {
                        filtered = filtered.filter { subject in
                            subject.value.label == label
                        }
                    }

                    if let query = query {
                        let trimmed = (query as NSString).trimmingCharacters(in: CharacterSet.whitespaces)
                        if !trimmed.isEmpty {
                            filtered = filtered.filter { subject in
                                Self.search(needle: trimmed, haystack: subject.value.name)
                            }
                        }
                    }

                    return Self.sort(filtered, using: sort)
                }
            }
            .eraseToAnyPublisher()
        super.init(filter: filter)
    }

    @available(*, unavailable)
    override func update(with new: [(String, StandardTorrent)]) {
        fatalError("Unimplemented")
    }

    func update(with torrents: [StandardTorrent]) {
        super.update(with: torrents.map { ($0.hash, $0) })
    }

    private static func search(needle: String, haystack: String) -> Bool {
        let delimiters = CharacterSet([" ", ".", "-", "_"])
        let normalizedNeedle = needle.lowercased().components(separatedBy: delimiters).joined(separator: " ")
        let normalizedHaystack = haystack.lowercased().components(separatedBy: delimiters).joined(separator: " ")
        return normalizedHaystack.contains(normalizedNeedle)
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func sort(
        _ torrents: [CurrentValueSubject<StandardTorrent, Never>],
        using sortOption: SortOption
    ) -> [CurrentValueSubject<StandardTorrent, Never>] {
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
        }

        return torrents.sorted { subject1, subject2 -> Bool in
            let obj1 = subject1.value
            let obj2 = subject2.value
            switch compare(obj1, obj2) {
            case .orderedAscending:
                return sortOption.direction == .ascending
            case .orderedDescending:
                return sortOption.direction == .descending
            case .orderedSame:
                if sortOption.property != .name {
                    let result = obj1.name.compare(obj2.name, options: [.numeric, .caseInsensitive])
                    switch result {
                    case .orderedAscending:
                        return true
                    case .orderedDescending:
                        return false
                    case .orderedSame:
                        break
                    }
                }

                return obj1.hash < obj2.hash
            }
        }
    }
}
