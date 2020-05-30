import Combine
import CommonModels
import LinkPresentation
@testable import Magnesium
import ViewModel
import XCTest

class TorrentDetailCoordinatorTests: TestCase {
    private var window: UIWindow!
    private var viewModel: MockViewModel!
    private var coordinator: TorrentDetailCoordinator!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        window = UIWindow()
        viewModel = MockViewModel()
        coordinator = TorrentDetailCoordinator(viewModel: AnyViewModel(viewModel))
        cancellables = Set()
        coordinator.viewModelEventPublisher
            .sink { [weak coordinator] in coordinator?.send($0) }
            .store(in: &cancellables)
        // the view controller needs to be in a key window to perform a presentation
        window.rootViewController = coordinator.presentable.viewController
        window.makeKeyAndVisible()
    }

    // MARK: - Presentable

    func test_presentable_shouldBeTorrentDetailViewController() {
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController, TorrentDetailViewController<AnyTorrentDetailViewModel>.self)
    }

    // MARK: - Handle TorrentDetailEvent

    func test_complete_shouldEmitCompleteEvent() throws {
        let event = try coordinator.eventPublisher.first().wait {
            self.viewModel.eventSubject.send(.complete)
        }.value()
        XCTAssertCase(event, .complete)
    }

    func test_alert_shouldPresentAlertController() {
        viewModel.eventSubject.send(.alert(Alert(title: "", style: .alert)))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController.presentedViewController, UIAlertController.self)
    }

    func test_activities_shouldPresentActivityViewController() {
        viewModel.eventSubject.send(.activities(
            [],
            torrent: .mock(),
            source: .view(UIView(), rect: .zero)
        ))
        let viewController = coordinator.presentable.viewController
        XCTAssertType(viewController.presentedViewController, UIActivityViewController.self)
    }

    func test_moveDownloadFolder_shouldPresentAlertController() {
        viewModel.eventSubject.send(.moveDownloadFolder(currentPath: "/path", subject: PassthroughSubject()))
        let viewController = coordinator.presentable.viewController
        let alertController = viewController.presentedViewController as! UIAlertController
        XCTAssertEqual(alertController.title, "Move Download Folder")
        XCTAssertEqual(alertController.actions.map(\.title), ["Save", "Cancel"])
        XCTAssertEqual(alertController.textFields?.count ?? 0, 1)
        let textField = alertController.textFields![0]
        XCTAssertEqual(textField.textContentType, .URL)
        XCTAssertEqual(textField.placeholder, "/downloads")
        XCTAssertEqual(textField.text, "/path")
    }
}

// MARK: - Mocks

private final class MockViewModel: ViewModel {
    let values = TorrentDetailViewValues.mock()
    let eventSubject = PassthroughSubject<TorrentDetailViewModelEvent, Never>()
    var eventPublisher: AnyPublisher<TorrentDetailViewModelEvent, Never> { eventSubject.eraseToAnyPublisher() }
    func send(_ event: TorrentDetailViewEvent) {}
}
