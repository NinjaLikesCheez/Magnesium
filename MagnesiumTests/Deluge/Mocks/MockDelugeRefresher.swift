//
//  MockDelugeRefresher.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-01-25.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium

final class MockDelugeRefresher: DelugeRefreshable {
    private let client: DelugeClient

    init(client: DelugeClient) {
        self.client = client
    }

    func refreshDeluge() -> AnyPublisher<Void, DelugeError> {
        return client.getCurrentState().map { _ in () }.eraseToAnyPublisher()
    }
}
