//
//  TransmissionTorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Preferences
import ViewModel

final class TransmissionTorrentDetailViewModel: StandardTorrentDetailViewModel<
    TransmissionTorrentDetailViewModel.Torrent,
    TransmissionTorrentFile
>, StandardTorrentDetailViewModelImplementation {
    private let subject: CurrentValueSubject<TransmissionTorrent, Never>
    private let client: TransmissionClient
    private let refresher: TransmissionRefreshable
    private var observers = [AnyCancellable]()

    init(
        subject: CurrentValueSubject<TransmissionTorrent, Never>,
        client: TransmissionClient,
        preferences: Preferences,
        refresher: TransmissionRefreshable
    ) {
        self.subject = subject
        self.client = client
        self.refresher = refresher
        let mappedSubject = CurrentValueSubject<Torrent, Never>(Torrent(subject.value))
        subject.sink { mappedSubject.send(Torrent($0)) }.store(in: &observers)
        super.init(subject: mappedSubject, preferences: preferences)
        setup(with: self)
    }

    func refresh() -> AnyPublisher<Void, Error> {
        return refresher.refreshTransmission().mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func pause() -> AnyPublisher<Void, Error> {
        return client.stop(ids: [subject.value.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func resume() -> AnyPublisher<Void, Error> {
        return client.start(ids: [subject.value.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func remove(removeData: Bool) -> AnyPublisher<Void, Error> {
        return client.remove(ids: [subject.value.id], removeData: removeData)
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }

    func recheck() -> AnyPublisher<Void, Error> {
        return client.verify(ids: [subject.value.id]).mapError { $0 as Error }.eraseToAnyPublisher()
    }

    func updateFiles() -> AnyPublisher<Void, Error> {
        return client.getTorrentFiles(id: subject.value.id)
            .handleEvents(receiveOutput: { [weak self] new in
                self?.files.update(with: new.map { ($0.index, $0) })
            })
            .map { _ in () }
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
}

extension TransmissionTorrentDetailViewModel {
    struct Torrent: StandardDetailTorrent {
        let torrent: TransmissionTorrent
        var hash: String { torrent.hash }
        var name: String { torrent.name }
        var standardState: TorrentState { torrent.standardState }
        var dateAdded: Date { torrent.dateAdded }
        var downloadRate: Int64 { torrent.downloadRate }
        var uploadRate: Int64 { torrent.uploadRate }
        var eta: TimeInterval { torrent.eta }
        var progress: Float { torrent.progress }
        var downloaded: Int64 { torrent.downloaded }
        var uploaded: Int64 { torrent.uploaded }
        var size: Int64 { torrent.size }
        var seeds: Int { torrent.seeds }
        var totalSeeds: Int { torrent.totalSeeds }
        var peers: Int { torrent.peers }
        var totalPeers: Int { torrent.totalPeers }
        var trackers: [String] { torrent.trackers.map { $0.host } }

        init(_ torrent: TransmissionTorrent) {
            self.torrent = torrent
        }
    }
}

extension TransmissionTorrentFile: StandardDetailTorrentFile {
    var progress: Float {
        return Float(downloaded) / Float(size)
    }
}
