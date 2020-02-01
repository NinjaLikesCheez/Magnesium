//
//  Deluge.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-18.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import Deluge
import Foundation

typealias DelugeError = Deluge.Client.Error
typealias DefaultDelugeClient = Deluge.Client
typealias DelugeTorrent = Deluge.Torrent
typealias DelugeTorrentFile = Deluge.TorrentFile

protocol DelugeClient {
    func authenticate() -> AnyPublisher<Void, DelugeError>
    func fetchTorrents() -> AnyPublisher<[DelugeTorrent], DelugeError>
    func fetchLabels() -> AnyPublisher<[String], DelugeError>
    func fetchTorrentFiles(hash: String) -> AnyPublisher<[DelugeTorrentFile], DelugeError>
    func pause(hashes: [String]) -> AnyPublisher<Void, DelugeError>
    func resume(hashes: [String]) -> AnyPublisher<Void, DelugeError>
    func remove(hashes: [String], removeData: Bool) -> AnyPublisher<Void, DelugeError>
    func recheck(hashes: [String]) -> AnyPublisher<Void, DelugeError>
    func add(url: URL) -> AnyPublisher<Void, DelugeError>
    func add(magnetURL: URL) -> AnyPublisher<Void, DelugeError>
    func add(fileURL: URL) -> AnyPublisher<Void, DelugeError>
}

extension DefaultDelugeClient: DelugeClient {}

extension DelugeTorrent: TorrentExt {
    var commonState: TorrentState {
        switch state {
        case .downloading:
            return .downloading
        case .seeding:
            return .seeding
        case .paused:
            return .paused
        case .checking:
            return .checking
        case .queued:
            return .queued
        case .error:
            return .error
        }
    }
}

extension DelugeTorrent: FilterableTorrent {}
