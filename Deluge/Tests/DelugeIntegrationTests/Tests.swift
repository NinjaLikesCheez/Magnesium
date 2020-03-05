import Combine
import Deluge
import XCTest

class DelugeIntegrationTests: XCTestCase {
    enum Resources {
        static let debianHash = "5a8062c076fa85e8056451c0d9aa04349ae27909"
        static let magnetURL = """
            magnet:?xt=urn:btih:54da0b79719064aa10fe2cc4e13630a1222d1939&dn=archlinux-2020.03.01-x86_64.iso\
            &tr=udp://tracker.archlinux.org:6969&tr=http://tracker.archlinux.org:6969/announce
            """
        static let magnetHash = "54da0b79719064aa10fe2cc4e13630a1222d1939"
    }

    private var client: Client!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        client = Client(baseURL: URL(string: "http://server:8112")!, password: "deluge")
        cancellables = Set()
    }

    private func urlForResource(named resourceName: String) -> URL {
        return URL(fileURLWithPath: #file).deletingLastPathComponent().appendingPathComponent(resourceName)
    }

    func test_addFileURL() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        client.request(.add(fileURL: urlForResource(named: "debian.torrent")))
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                },
                receiveValue: { hash in
                    XCTAssertEqual(hash, Resources.debianHash)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func test_addFileURLs() {
        let urls = [
            urlForResource(named: "mint.torrent"),
            urlForResource(named: "ubuntu.torrent"),
        ]
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        client.request(.add(fileURLs: urls))
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                },
                receiveValue: { _ in
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func test_addMagnetLink() {
        let url = URL(string: Resources.magnetURL)!
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        client.request(.add(magnetURL: url))
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                },
                receiveValue: { hash in
                    XCTAssertEqual(hash, Resources.magnetHash)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func test_removeTorrents_error() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        client.request(.remove(hashes: ["a"], removeData: false))
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                },
                receiveValue: { errors in
                    XCTAssertEqual(errors.count, 1)
                    XCTAssertEqual(errors.first?.hash, "a")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }

    func test_updateUI() {
        let expectation = self.expectation(description: #function)
        expectation.expectedFulfillmentCount = 2
        client.request(.add(fileURL: urlForResource(named: "debian.torrent")))
            .replaceError(with: Resources.debianHash)
            .setFailureType(to: Client.Error.self)
            .flatMap { _ in self.client.request(.updateUI(properties: ["hash", "trackers"])) }
            .sink(
                receiveCompletion: { completion in
                    if case let .failure(error) = completion {
                        XCTFail(String(describing: error))
                    }
                    expectation.fulfill()
                },
                receiveValue: { state in
                    let torrent = state.torrents.first(where: { $0.hash == Resources.debianHash })
                    XCTAssertNotNil(torrent)
                    XCTAssertEqual(torrent?.trackers?.count, 1)
                    XCTAssertEqual(torrent?.trackers?.first?.url, "http://bttracker.debian.org:6969/announce")
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        waitForExpectations(timeout: 1)
    }
}
