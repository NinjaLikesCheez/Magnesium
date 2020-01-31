//
//  Publishers+AsOptional.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-30.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

extension Publisher {
    func asOptional() -> Publishers.Map<Self, Self.Output?> {
        return map { Optional.some($0) }
    }
}
