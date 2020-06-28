import Combine
import Transmission

struct TransmissionSession {
    let client: TransmissionClient
    let torrents = CurrentValueSubject<[StandardTorrent], Never>([])

    func refresh() -> AnyPublisher<[StandardTorrent], Error> {
        client.request(.torrentsForApp)
            .handleEvents(receiveOutput: {
                self.torrents.send($0)
            })
            .eraseError()
            .eraseToAnyPublisher()
    }
}

private extension Request {
    static var torrentsForApp: Request<[StandardTorrent]> {
        let properties: [Torrent.PropertyKeys] = [
            .bytesUnchecked,
            .bytesValid,
            .dateAdded,
            .downloadPath,
            .downloadRate,
            .eta,
            .hash,
            .name,
            .peers,
            .progress,
            .seeds,
            .size,
            .status,
            .totalPeers,
            .trackers,
            .uploaded,
            .uploadRate,
        ]

        return Self.torrents(properties: properties).map { $0.compactMap(StandardTorrent.init) }
    }
}
