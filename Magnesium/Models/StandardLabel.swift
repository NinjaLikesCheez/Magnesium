//
//  StandardLabel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-06.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Foundation

protocol StandardLabel {
    var name: String { get }
    var count: Int { get }
}

extension StandardLabel {
    var displayName: String {
        return name.isEmpty ? "None" : name
    }
}
