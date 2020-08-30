import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class TorrentListViewControllerTests: TestCase {
    func test_snapshot_whenEmpty() {
        let values = TorrentListViewValues.mock(title: "Server")
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenLoading() {
        let values = TorrentListViewValues.mock(title: "Server", isLoading: true)
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_withTorrents() {
        let torrents = [StandardTorrent.visualMock]
        let values = TorrentListViewValues.mock(
            title: "Server",
            items: torrents.map { .init(torrentSubject: .init($0)) },
            status: "↓ 1.5 MB/s ↑ 454 KB/s"
        )
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }

    func test_snapshot_withActiveFilters() {
        let values = TorrentListViewValues.mock(title: "Server", hasActiveFilters: true)
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_snapshot_whenEditing() {
        let torrents = [StandardTorrent.visualMock]
        let values = TorrentListViewValues.mock(
            title: "0 Selected",
            items: torrents.map { TorrentListItem(torrentSubject: CurrentValueSubject($0)) },
            isEditing: true
        )
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }

    func test_snapshot_whenEditing_withSelection() {
        let torrents = [StandardTorrent.visualMock]
        let values = TorrentListViewValues.mock(
            title: "1 Selected",
            items: torrents.map { TorrentListItem(torrentSubject: CurrentValueSubject($0)) },
            isEditing: true,
            editActionsEnabled: true
        )
        let viewModel = StaticViewModel(event: TorrentListViewEvent.self, values: values)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()

        let expectation = self.expectation(description: #function)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            viewController.tableView.selectRow(at: .init(row: 0, section: 0), animated: false, scrollPosition: .none)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)

        assertSnapshot(matching: navigationController, as: .image)
    }
}

private extension StandardTorrent {
    static var visualMock: StandardTorrent {
        .mock(
            downloaded: Int64(5_000_000_000 * 0.4),
            downloadRate: 1_540_527,
            eta: 67 * 63 * 1,
            name: "Name 1",
            progress: 0.4,
            size: 5_000_000_000,
            uploadRate: 465_158
        )
    }
}
