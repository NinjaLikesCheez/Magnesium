import Combine

struct StandardTorrentDetailImplementation<Torrent: StandardTorrent, Label: StandardLabel, File: StandardTorrentFile> {
    var refresh: () -> AnyPublisher<Void, Error>
    var refreshFiles: (Torrent) -> AnyPublisher<[File], Error>
    var pause: (Torrent) -> AnyPublisher<Void, Error>
    var resume: (Torrent) -> AnyPublisher<Void, Error>
    var remove: (Torrent, Bool) -> AnyPublisher<Void, Error>
    var verify: (Torrent) -> AnyPublisher<Void, Error>
    var setLabel: (Label, Torrent) -> AnyPublisher<Void, Error>
    var updateTrackers: (Torrent) -> AnyPublisher<Void, Error>
    var moveDownloadFolder: (String, Torrent) -> AnyPublisher<Void, Error>
}
