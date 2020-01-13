//
//  MockTorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Navigator

final class MockTorrentListViewModel: TorrentListViewModel, MockTorrentServerRefreshable {
    private typealias TorrentSubject = CurrentValueSubject<MockTorrent, Never>
    private typealias TorrentMap = [Int: TorrentSubject]

    private let navigator: Navigator
    private var torrentMapSubject: CurrentValueSubject<TorrentMap, Never>
    private var torrentMapObserver: AnyCancellable?
    private var torrentSubjects: CurrentValueSubject<[TorrentSubject], Never>
    private var observers = [AnyCancellable]()

    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> {
        return torrentSubjects
            .map { subjects -> [AnyTorrentListItemViewModel] in
                subjects.map { MockTorrentListItemViewModel(torrentSubject: $0).eraseToAny() }
            }
            .ui()
            .eraseToAnyPublisher()
    }

    var torrentsUpdated: AnyPublisher<[MockTorrent], Never> {
        return torrentSubjects.dropFirst().map { $0.map { $0.value } }.eraseToAnyPublisher()
    }

    private static func torrents() -> [MockTorrent] {
        let names = ["Application", "Movie", "TV Show", "Book", "Album"]
        let states = [TorrentState.seeding, .downloading, .paused, .queued, .error, .downloading, .seeding, .checking]
        var torrents = [MockTorrent]()

        for index in 1 ..< 26 {
            let name = "\(names[index % names.count]) \(Int(ceil(Double(index) / Double(names.count))))"
            let state = states[index % states.count]
            let size = Int64(1024 * 1024 * 1024 * Double(index) * Double.random(in: 0 ... 1))
            let downloaded = state != .seeding ? Int64(Double(size) * Double.random(in: 0 ... 1)) : size
            let uploaded = Int64(Double(downloaded) * 3 * Double.random(in: 0 ... 1))
            let downloadRate = state == .downloading ? Int(1024 * 100 * Double(index) * Double.random(in: 0 ... 1)) : 0
            let uploadRate = state == .seeding ? Int(1024 * 100 * Double(index) * Double.random(in: 0 ... 1)) : 0
            let eta = state == .downloading ? TimeInterval(Double(size - downloaded) / Double(downloadRate)) : 0
            let trackers = ["https://tracker.example.com/\(UUID().uuidString)", "https://tracker2.example.com"]

            torrents.append(MockTorrent(
                id: index,
                name: name,
                state: state,
                size: size,
                downloaded: downloaded,
                uploaded: uploaded,
                downloadRate: downloadRate,
                uploadRate: uploadRate,
                eta: eta,
                seeds: 0,
                totalSeeds: 0,
                peers: 0,
                totalPeers: 0,
                trackers: trackers
            ))
        }

        return torrents
    }

    init(navigator: Navigator) {
        self.navigator = navigator
        torrentSubjects = CurrentValueSubject([])
        torrentMapSubject = CurrentValueSubject([:])
        torrentMapObserver = torrentMapSubject.sink { [weak self] in
            self?.torrentSubjects.send($0.values.sorted { $0.value.id < $1.value.id })
        }
        refresh()
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
            .store(in: &observers)
    }

    func refresh() -> AnyPublisher<Never, Error> {
        return Future<Void, Error> { [weak self] completion in
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
                self?._refresh()
                completion(.success(()))
            }
        }
        .ignoreOutput()
        .ui()
        .eraseToAnyPublisher()
    }

    private func _refresh() {
        let new: TorrentMap = MockTorrentListViewModel.torrents()
            .reduce(into: [:]) { $0[$1.id] = CurrentValueSubject($1) }
        torrentMapSubject.send(
            torrentMapSubject.value
                .filter { new[$0.key] != nil }
                .merging(new) { current, new in
                    current.send(new.value)
                    return current
                }
        )
    }

    func didSelectItem(at index: Int) {
        let subject = torrentSubjects.value[index]
        let viewModel = MockTorrentDetailViewModel(torrentSubject: subject, refresher: self)
        navigator.showDetail(NavigationControllerScreen(Screens.Torrents.detail(viewModel: viewModel)))
    }
}
