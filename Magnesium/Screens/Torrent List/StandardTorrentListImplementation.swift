import Combine

struct StandardTorrentListImplementation {
    struct AddLinkError: Error {
        let title: String
        let message: String
    }

    var updatePublisher: AnyPublisher<([StandardTorrent], [StandardLabel]), Never>
    var refresh: () -> AnyPublisher<([StandardTorrent], [StandardLabel]), Error>
    var detailViewModel: (
        CurrentValueSubject<StandardTorrent, Never>,
        CurrentValueSubject<[StandardLabel], Never>
    ) -> AnyTorrentDetailViewModel
    var addLink: (String) -> AnyPublisher<Void, AddLinkError>
    var pause: ([StandardTorrent]) -> AnyPublisher<Void, Error>
    var resume: ([StandardTorrent]) -> AnyPublisher<Void, Error>
    var remove: ([StandardTorrent], Bool) -> AnyPublisher<Void, Error>
    var verify: ([StandardTorrent]) -> AnyPublisher<Void, Error>
    var setLabel: (StandardLabel, [StandardTorrent]) -> AnyPublisher<Void, Error>
    var updateTrackers: ([StandardTorrent]) -> AnyPublisher<Void, Error>
    var moveDownloadFolder: (String, [StandardTorrent]) -> AnyPublisher<Void, Error>
}
