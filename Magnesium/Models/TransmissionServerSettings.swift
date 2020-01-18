//
//  TransmissionServerSettings.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

struct TransmissionServerSettings: Codable {
    var url: URL
    var username: String?
    var password: String? // TODO: keychain
}
