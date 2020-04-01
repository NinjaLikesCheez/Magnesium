import Combine
import Deluge

struct DelugeSession {
    let client: DelugeClient
    let torrents = CurrentValueSubject<[DelugeTorrent], Never>([])
    let labels = CurrentValueSubject<[DelugeLabel], Never>([])

    func refresh() -> AnyPublisher<([DelugeTorrent], [DelugeLabel]), Error> {
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
    static var updateUIForApp: Request<([DelugeTorrent], [DelugeLabel])> {
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

        return Self.updateUI(properties: properties).map { ($0.compactMap(DelugeTorrent.init), $1) }
    }
}
