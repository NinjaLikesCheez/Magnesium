//
//  TransmissionTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Navigator
import Preferences

final class TransmissionTorrentListViewModel: TorrentListViewModel, TorrentListViewModelExt {
    private typealias TorrentSubject = CurrentValueSubject<TransmissionTorrent, Never>
    private typealias TorrentMap = [Int: TorrentSubject]

    private let client: TransmissionClient
    private var observers = [AnyCancellable]()
    private var torrentMap: CurrentValueSubject<TorrentMap, Never>
    private var torrentMapObserver: AnyCancellable?
    private var torrentSubjects: CurrentValueSubject<[TorrentSubject], Never>
    private var sortOption = CurrentValueSubject<SortOption, Never>(SortOption(property: .name))
    private var autoUpdateTimer: Timer?

    let preferences: Preferences
    var navigator: Navigator?
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> {
        return torrentSubjects
            .combineLatest(sortOption)
            .map { TransmissionTorrentListViewModel.sort($0, using: $1) }
            .map { $0.map { TransmissionTorrentListItemViewModel(torrentSubject: $0).eraseToAny() } }
            .ui()
            .eraseToAnyPublisher()
    }

    private static func sort(
        _ torrents: [TorrentSubject],
        using sortOption: SortOption
    ) -> [TorrentSubject] {
        let compare: (TransmissionTorrent, TransmissionTorrent) -> ComparisonResult
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
                if obj1.name != obj2.name {
                    return obj1.name < obj2.name
                }

                return obj1.id < obj2.id
            }
        }
    }

    init(client: TransmissionClient, preferences: Preferences) {
        self.client = client
        self.preferences = preferences
        torrentSubjects = CurrentValueSubject([])
        torrentMap = CurrentValueSubject([:])
        torrentMapObserver = torrentMap.sink { [weak self] in
            self?.torrentSubjects.send($0.values.sorted { $0.value.name < $1.value.name })
        }

        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)

        preferences.valuePublisher(for: PreferenceKeys.autoRefreshInterval)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] value in
                self?.configureAutoUpdateTimer(interval: value)
            })
            .store(in: &observers)
    }

    private func configureAutoUpdateTimer(interval: TimeInterval?) {
        guard let interval = interval, interval > 0 else {
            autoUpdateTimer?.invalidate()
            autoUpdateTimer = nil
            return
        }

        autoUpdateTimer?.invalidate()
        let timer = Timer(
            fireAt: Date().advanced(by: interval),
            interval: interval,
            target: self,
            selector: #selector(updateTimerFired(_:)),
            userInfo: nil,
            repeats: true
        )
        RunLoop.main.add(timer, forMode: .common)
        autoUpdateTimer = timer
    }

    @objc
    private func updateTimerFired(_ timer: Timer) {
        guard timer.isValid else { return }
        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refreshTorrents() -> AnyPublisher<Never, TransmissionClientError> {
        return client.getTorrents()
            .map { torrents -> TorrentMap in
                torrents.reduce(into: TorrentMap()) { map, torrent in
                    map[torrent.id] = CurrentValueSubject(torrent)
                }
            }
            .handleEvents(receiveOutput: { new in
                self.torrentMap.send(
                    self.torrentMap.value
                        .filter { new[$0.key] != nil }
                        .merging(new) { current, new in
                            current.send(new.value)
                            return current
                        }
                )
            })
            .ignoreOutput()
            .eraseToAnyPublisher()
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return refreshTorrents()
            .mapError { $0 as Error }
            .ui()
            .eraseToAnyPublisher()
    }

    func didSelectItem(at index: Int) {
        // TODO:
    }
}
