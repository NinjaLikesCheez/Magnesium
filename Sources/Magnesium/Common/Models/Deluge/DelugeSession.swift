import Combine
import Deluge

struct DelugeSession {
    let client: DelugeClient
    let torrents = CurrentValueSubject<[StandardTorrent], Never>([])
    let labels = CurrentValueSubject<[StandardLabel], Never>([])

    func refresh() -> AnyPublisher<([StandardTorrent], [StandardLabel]), Error> {
        client.request(.updateUIForApp)
            .handleEvents(receiveOutput: {
                self.torrents.send($0)
                self.labels.send($1)
            })
            .eraseError()
            .eraseToAnyPublisher()
    }
}

private extension Request {
    static var updateUIForApp: Request<([StandardTorrent], [StandardLabel])> {
        let properties: [Torrent.PropertyKeys] = [
            .dateAdded,
            .downloaded,
            .downloadPath,
            .downloadRate,
            .eta,
            .label,
            .name,
            .peers,
            .progress,
            .seeds,
            .size,
            .state,
            .totalPeers,
            .totalSeeds,
            .trackers,
            .uploaded,
            .uploadRate,
        ]

        return Self.updateUI(properties: properties).map { ($0.compactMap(StandardTorrent.init), $1.map(\.standard)) }
    }
}
