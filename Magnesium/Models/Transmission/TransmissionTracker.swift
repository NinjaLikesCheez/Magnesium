//
//  TransmissionTracker.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct TransmissionTracker {
    let id: Int
    let host: String
    let seeders: Int
}

extension TransmissionTracker {
    init?(dictionary: [String: Any]) {
        guard let id = dictionary["id"] as? Int,
            let host = dictionary["host"] as? String,
            let seeders = dictionary["seederCount"] as? Int
        else {
            return nil
        }

        self.id = id
        self.host = host
        self.seeders = seeders
    }
}
