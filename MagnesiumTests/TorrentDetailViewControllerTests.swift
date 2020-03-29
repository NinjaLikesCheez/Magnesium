import Combine
@testable import Magnesium
import SnapshotTesting
import XCTest

class TorrentDetailViewControllerTests: TestCase {
    func test_view() {
        let torrent = MockTorrent(name: "Name", label: "label")
        let viewRep = TorrentDetailViewRepresentation(
            hash: "",
            sections: Just([
                .init(type: .header, items: [.header(.init(torrent: .init(torrent)))]),
                .init(type: .info, items: [
                    .info(.init(
                        name: "Name",
                        value: Just("Value").eraseToAnyPublisher(),
                        expandedValue: Just("Expanded").eraseToAnyPublisher()
                    )),
                    .info(.init(
                        name: "Another Name",
                        value: Just("Value").eraseToAnyPublisher(),
                        expandedValue: Just("Expanded").eraseToAnyPublisher()
                    )),
                ]),
                .init(type: .trackers, items: [
                    .tracker("udp://tracker.example.com:9000"),
                    .tracker("http://tracker.example.com:9000/announce"),
                ]),
                .init(type: .files, items: [
                    .file(.init(file: .init(MockTorrentFile(index: 0, name: "Name")))),
                    .file(.init(file: .init(MockTorrentFile(index: 1, name: "Name")))),
                ]),
            ]).eraseToAnyPublisher(),
            isRefreshing: Just(false).eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(view: viewRep, type: TorrentDetailViewEvent.self)
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        viewController.loadViewIfNeeded()
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }
}
