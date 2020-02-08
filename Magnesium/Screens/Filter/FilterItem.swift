//
//  FilterItem.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

enum FilterItem: Equatable, Hashable {
    case sort(String)
    case state(String)
    case label(String)
}
