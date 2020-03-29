import Combine
@testable import Magnesium
import SnapshotTesting
import ViewModel
import XCTest

class TorrentListViewControllerTests: TestCase {
    func test_emptyState() {
        let values = TorrentListViewValues(
            title: Just("Server").eraseToAnyPublisher(),
            items: Just([]).eraseToAnyPublisher(),
            isLoading: Just(false).eraseToAnyPublisher(),
            isEditing: Just(false).eraseToAnyPublisher(),
            hasActiveFilters: Just(false).eraseToAnyPublisher(),
            editActionsEnabled: Just(false).eraseToAnyPublisher(),
            status: Just("").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_loadingState() {
        let values = TorrentListViewValues(
            title: Just("Server").eraseToAnyPublisher(),
            items: Just([]).eraseToAnyPublisher(),
            isLoading: Just(true).eraseToAnyPublisher(),
            isEditing: Just(false).eraseToAnyPublisher(),
            hasActiveFilters: Just(false).eraseToAnyPublisher(),
            editActionsEnabled: Just(false).eraseToAnyPublisher(),
            status: Just("").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_items() {
        let torrents = [MockTorrent.visualMock]
        let values = TorrentListViewValues(
            title: Just("Server").eraseToAnyPublisher(),
            items: Just(torrents.map { TorrentListItem(torrent: CurrentValueSubject($0)) }).eraseToAnyPublisher(),
            isLoading: Just(false).eraseToAnyPublisher(),
            isEditing: Just(false).eraseToAnyPublisher(),
            hasActiveFilters: Just(false).eraseToAnyPublisher(),
            editActionsEnabled: Just(false).eraseToAnyPublisher(),
            status: Just("↓ 1.5 MB/s ↑ 454 KB/s").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }

    func test_activeFilters() {
        let values = TorrentListViewValues(
            title: Just("Server").eraseToAnyPublisher(),
            items: Just([]).eraseToAnyPublisher(),
            isLoading: Just(false).eraseToAnyPublisher(),
            isEditing: Just(false).eraseToAnyPublisher(),
            hasActiveFilters: Just(true).eraseToAnyPublisher(),
            editActionsEnabled: Just(false).eraseToAnyPublisher(),
            status: Just("").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        assertSnapshot(matching: navigationController, as: .image)
    }

    func test_editing() {
        let torrents = [MockTorrent.visualMock]
        let values = TorrentListViewValues(
            title: Just("0 Selected").eraseToAnyPublisher(),
            items: Just(torrents.map { TorrentListItem(torrent: CurrentValueSubject($0)) }).eraseToAnyPublisher(),
            isLoading: Just(false).eraseToAnyPublisher(),
            isEditing: Just(true).eraseToAnyPublisher(),
            hasActiveFilters: Just(false).eraseToAnyPublisher(),
            editActionsEnabled: Just(false).eraseToAnyPublisher(),
            status: Just("").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
        let viewController = TorrentListViewController(viewModel: viewModel)
        let navigationController = UINavigationController(rootViewController: viewController)
        viewController.loadViewIfNeeded()
        assertSnapshot(matching: navigationController, as: .wait(for: 0.1, on: .image))
    }

    func test_editing_withSelection() {
        let torrents = [MockTorrent.visualMock]
        let values = TorrentListViewValues(
            title: Just("1 Selected").eraseToAnyPublisher(),
            items: Just(torrents.map { TorrentListItem(torrent: CurrentValueSubject($0)) }).eraseToAnyPublisher(),
            isLoading: Just(false).eraseToAnyPublisher(),
            isEditing: Just(true).eraseToAnyPublisher(),
            hasActiveFilters: Just(false).eraseToAnyPublisher(),
            editActionsEnabled: Just(true).eraseToAnyPublisher(),
            status: Just("").eraseToAnyPublisher()
        )
        let viewModel = StaticViewModel(values: values, type: TorrentListViewEvent.self)
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

private extension MockTorrent {
    static var visualMock: MockTorrent {
        .init(
            name: "Name 1",
            downloadRate: 1_540_527,
            uploadRate: 465_158,
            eta: 67 * 63 * 1,
            progress: 0.4,
            downloaded: Int64(5_000_000_000 * 0.4),
            size: 5_000_000_000
        )
    }
}
