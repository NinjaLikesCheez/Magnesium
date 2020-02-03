//
//  MockTransmissionRefresher.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
@testable import Magnesium

final class MockTransmissionRefresher: TransmissionRefreshable {
    private let client: TransmissionClient

    init(client: TransmissionClient) {
        self.client = client
    }

    func refreshTransmission() -> AnyPublisher<Void, TransmissionError> {
        return client.getTorrents().map { _ in () }.eraseToAnyPublisher()
    }
}
