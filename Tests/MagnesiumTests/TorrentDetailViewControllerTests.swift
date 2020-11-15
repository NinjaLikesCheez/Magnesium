import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class TorrentDetailViewControllerTests: TestCase {
    func test_snapshot() {
        let torrent = StandardTorrent.mock(label: "label", name: "Name")
        let values = TorrentDetailViewValues.mock(
            sections: [
                .init(type: .header, items: [.header(.init(torrentSubject: .init(torrent)))]),
                .init(type: .info, items: [
                    .info(.init(
                        name: "Name",
                        value: .init("Value"),
                        expandedValue: .init("Expanded")
                    )),
                    .info(.init(
                        name: "Another Name",
                        value: .init("Value"),
                        expandedValue: .init("Expanded")
                    )),
                ]),
                .init(type: .trackers, items: [
                    .tracker("udp://tracker.example.com:9000"),
                    .tracker("http://tracker.example.com:9000/announce"),
                ]),
                .init(type: .files, items: [
                    .file(.init(fileSubject: .init(.mock(index: 0, name: "File 1")))),
                    .file(.init(fileSubject: .init(.mock(index: 1, name: "File 2")))),
                ]),
            ]
        )
        let viewModel = StaticViewModel(event: TorrentDetailViewEvent.self, values: values)
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        viewController.loadViewIfNeeded()
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }

    func test_snapshot_whenEditingFilesSection() {
        let values = TorrentDetailViewValues.mock(
            sections: [
                .init(type: .files, items: [
                    .file(.init(fileSubject: .init(.mock(index: 0, name: "File 1")))),
                    .file(.init(fileSubject: .init(.mock(index: 1, name: "File 2")))),
                ]),
            ],
            editSection: .files,
            toolbarInfo: L10n.Common.selectedCount(1)
        )
        let viewModel = StaticViewModel(event: TorrentDetailViewEvent.self, values: values)
        let viewController = TorrentDetailViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()

        let expectation = self.expectation(description: #function)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewController.tableView.selectRow(at: .init(row: 0, section: 0), animated: false, scrollPosition: .none)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }
}
