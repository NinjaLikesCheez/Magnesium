//
//  TransmissionRefreshable.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol TransmissionRefreshable {
    func refreshTransmission() -> AnyPublisher<Void, TransmissionError>
}
