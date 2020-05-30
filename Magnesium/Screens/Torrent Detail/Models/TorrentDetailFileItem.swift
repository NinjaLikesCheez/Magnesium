import Combine

struct TorrentDetailFileItem: Identifiable {
    let id: Int
    var name: AnyPublisher<String, Never>
    var size: AnyPublisher<String, Never>
    var progress: AnyPublisher<String, Never>

    init(fileSubject: CurrentValueSubject<StandardTorrentFile, Never>) {
        id = fileSubject.value.index
        name = fileSubject.map(\.name).ui().eraseToAnyPublisher()
        size = fileSubject.map { Formatters.bytes.string(fromByteCount: $0.size) }.ui().eraseToAnyPublisher()
        progress = fileSubject.map { Formatters.percentage.string(for: $0.progress) ?? "" }.ui().eraseToAnyPublisher()
    }
}
