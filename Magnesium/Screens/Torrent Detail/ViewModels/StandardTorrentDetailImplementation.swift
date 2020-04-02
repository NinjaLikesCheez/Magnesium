import Combine

struct StandardTorrentDetailImplementation {
    var refresh: () -> AnyPublisher<Void, Error>
    var refreshFiles: (StandardTorrent) -> AnyPublisher<[StandardTorrentFile], Error>
    var pause: (StandardTorrent) -> AnyPublisher<Void, Error>
    var resume: (StandardTorrent) -> AnyPublisher<Void, Error>
    var remove: (StandardTorrent, Bool) -> AnyPublisher<Void, Error>
    var verify: (StandardTorrent) -> AnyPublisher<Void, Error>
    var setLabel: (StandardLabel, StandardTorrent) -> AnyPublisher<Void, Error>
    var updateTrackers: (StandardTorrent) -> AnyPublisher<Void, Error>
    var moveDownloadFolder: (String, StandardTorrent) -> AnyPublisher<Void, Error>
}
