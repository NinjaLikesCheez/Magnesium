import Combine
import LinkPresentation
@testable import Magnesium
import MVVMModels
import ViewModel
import XCTest

class TorrentDetailCoordinatorTests: XCTestCase {
    private var window: UIWindow!
    private var viewModel: MockViewModel!
    private var coordinator: TorrentDetailCoordinator<AnyTorrentDetailViewModel>!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        window = UIWindow()
        viewModel = MockViewModel()
        coordinator = TorrentDetailCoordinator(viewModel: AnyEmitterViewModel(viewModel))
        coordinator.received.sink { [weak coordinator] in coordinator?.handle($0) }.store(in: &cancellables)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentDetailViewController() {
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController) === TorrentDetailViewController<AnyTorrentDetailViewModel>.self else {
            XCTFail("Unexpected view controller: \(String(describing: self))")
            return
        }
    }

    // MARK: - Handle TorrentDetailEvent

    func test_complete_shouldEmitCompleteEvent() {
        var event: TorrentDetailCoordinatorEvent?
        coordinator.events.first().sink { event = $0 }.store(in: &cancellables)
        viewModel.eventSubject.send(.complete)
        guard case .complete = event else {
            XCTFail("Unexpected event: \(String(describing: event))")
            return
        }
    }

    func test_alert_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(Alert(title: "", message: nil, style: .alert)))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIAlertController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController.presentedViewController))")
            return
        }
    }

    func test_activities_shouldPresentActivityViewController() {
        viewModel.eventSubject.send(.activities(
            [],
            torrent: DelugeTorrent.mock(),
            source: .view(UIView(), rect: .zero)
        ))
        let viewController = coordinator.presentable.viewController
        guard type(of: viewController.presentedViewController!) === UIActivityViewController.self else {
            XCTFail("Unexpected view controller: \(String(describing: viewController.presentedViewController))")
            return
        }
    }

    func test_moveDownloadFolder_shouldPresentAlertController() {
        viewModel.eventSubject.send(.moveDownloadFolder(currentPath: "/path", subject: PassthroughSubject()))
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Move Download Folder")
        XCTAssertEqual(alertController.actions.map { $0.title }, ["Save", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        let textField = alertController.textFields![0]
        XCTAssertEqual(textField.textContentType, .URL)
        XCTAssertEqual(textField.placeholder, "/downloads")
        XCTAssertEqual(textField.text, "/path")
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel, EventEmitter {
    let state = TorrentDetailViewState(
        hash: "",
        sections: Just([]).eraseToAnyPublisher(),
        isRefreshing: Just(false).eraseToAnyPublisher()
    )
    let eventSubject = PassthroughSubject<TorrentDetailEvent, Never>()
    var events: AnyPublisher<TorrentDetailEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func handle(_ event: TorrentDetailViewEvent) {}
}
