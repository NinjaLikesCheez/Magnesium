//
//  FilterSection.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct FilterSection: Equatable {
    enum SectionType: Equatable {
        case sort
        case filters
    }

    let type: SectionType
    var items: [FilterItem]
}
