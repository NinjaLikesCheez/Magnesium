//
//  Transmission.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Foundation
import Transmission

typealias TransmissionError = Transmission.Client.Error
typealias DefaultTransmissionClient = Transmission.Client
typealias TransmissionTorrent = Transmission.Torrent
typealias TransmissionTorrentFile = Transmission.TorrentFile

protocol TransmissionClient {
    func authenticate() -> AnyPublisher<Void, TransmissionError>
    func getTorrents() -> AnyPublisher<[Torrent], TransmissionError>
    func getTorrentFiles(id: Int) -> AnyPublisher<[TransmissionTorrentFile], TransmissionError>
    func start(ids: [Int]) -> AnyPublisher<Void, TransmissionError>
    func stop(ids: [Int]) -> AnyPublisher<Void, TransmissionError>
    func remove(ids: [Int], removeData: Bool) -> AnyPublisher<Void, TransmissionError>
    func verify(ids: [Int]) -> AnyPublisher<Void, TransmissionError>
    func add(url: URL) -> AnyPublisher<Void, TransmissionError>
    func add(fileURL: URL) -> AnyPublisher<Void, TransmissionError>
}

extension DefaultTransmissionClient: TransmissionClient {}

extension TransmissionTorrent: StandardTorrent {
    var standardState: TorrentState {
        switch status {
        case .paused:
            return .paused
        case .checkQueued:
            return .queued
        case .checking:
            return .checking
        case .downloadQueued:
            return .queued
        case .downloading:
            return .downloading
        case .seedQueued:
            return .queued
        case .seeding:
            return .seeding
        case .isolated:
            return .error
        }
    }

    var trackerStrings: [String] {
        return trackers.map { $0.host }
    }

    var label: String {
        return ""
    }
}

extension TransmissionTorrentFile: StandardTorrentFile {
    var progress: Float {
        return Float(downloaded) / Float(size)
    }
}
