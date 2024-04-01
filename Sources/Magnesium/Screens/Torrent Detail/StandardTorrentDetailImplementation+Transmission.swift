import Combine
import Transmission

extension StandardTorrentDetailImplementation {
    static func transmission(session: TransmissionSession) -> Self {
        let client = session.client
        return .init(
            refresh: { refresh(session: session) },
            refreshFiles: { refreshFiles(client: client, torrent: $0) },
            pause: { pause(client: client, torrent: $0) },
            resume: { resume(client: client, torrent: $0) },
            remove: { remove(client: client, torrent: $0, removeData: $1) },
            verify: { verify(client: client, torrent: $0) },
            setLabel: { _, _ in Just(()).setFailureType(to: Error.self).eraseToAnyPublisher() },
            updateTrackers: { updateTrackers(client: client, torrent: $0) },
            moveDownloadFolder: { moveDownloadFolder(client: client, path: $0, torrent: $1) },
            paths: { paths(client: client, torrent: $0 )},
            setPriority: { setPriority(client: client, torrent: $0, files: $1, priorities: $2) }
        )
    }

    private static func refresh(session: TransmissionSession) -> AnyPublisher<Void, Error> {
        session.refresh().asVoid().eraseToAnyPublisher()
    }

    private static func refreshFiles(
        client: TransmissionClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<[StandardTorrentFile], Error> {
        client.request(.torrentFiles(id: torrent.hash)).map { $0.map(\.standard) }.eraseError().eraseToAnyPublisher()
    }

    private static func paths(
        client: TransmissionClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<[String], Error> {
        client.request(.torrentFiles(id: torrent.hash)).map { $0.map(\.name) }.eraseError().eraseToAnyPublisher()
    }


    private static func pause(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.stop(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func resume(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.start(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func remove(
        client: TransmissionClient,
        torrent: StandardTorrent,
        removeData: Bool
    ) -> AnyPublisher<Void, Error> {
        client.request(.remove(ids: [torrent.hash], removeData: removeData)).eraseError().eraseToAnyPublisher()
    }

    private static func verify(client: TransmissionClient, torrent: StandardTorrent) -> AnyPublisher<Void, Error> {
        client.request(.verify(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func updateTrackers(
        client: TransmissionClient,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.reannounce(ids: [torrent.hash])).eraseError().eraseToAnyPublisher()
    }

    private static func moveDownloadFolder(
        client: TransmissionClient,
        path: String,
        torrent: StandardTorrent
    ) -> AnyPublisher<Void, Error> {
        client.request(.move(ids: [torrent.hash], path: path)).eraseError().eraseToAnyPublisher()
    }

    // swiftlint:disable:next cyclomatic_complexity
    private static func setPriority(
        client: TransmissionClient,
        torrent: StandardTorrent,
        files: [StandardTorrentFile],
        priorities: [StandardTorrentFile: TorrentPriority]
    ) -> AnyPublisher<Void, Error> {
        var low = [Int]()
        var normal = [Int]()
        var high = [Int]()
        var wanted = [Int]()
        var unwanted = [Int]()

        for (file, priority) in priorities {
            switch priority {
            case .low:
                low.append(file.index)
            case .normal:
                normal.append(file.index)
            case .high:
                high.append(file.index)
            case .disabled:
                break
            }

            if file.priority == .disabled, priority != .disabled {
                wanted.append(file.index)
            } else if file.priority != .disabled, priority == .disabled {
                unwanted.append(file.index)
            }
        }

        var options = [TorrentOption]()

        if !low.isEmpty {
            options.append(.priorityLow(indices: low))
        }

        if !normal.isEmpty {
            options.append(.priorityNormal(indices: normal))
        }

        if !high.isEmpty {
            options.append(.priorityHigh(indices: high))
        }

        if !wanted.isEmpty {
            options.append(.filesWanted(indices: wanted))
        }

        if !unwanted.isEmpty {
            options.append(.filesUnwanted(indices: unwanted))
        }

        return client.request(.setOptions(ids: [torrent.hash], options: options)).eraseError().eraseToAnyPublisher()
    }
}
