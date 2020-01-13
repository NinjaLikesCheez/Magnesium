//
//  TextInputTableViewCellViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol TextInputTableViewCellViewModel {
    var name: String { get }
    var placeholder: String { get }
    var value: CurrentValueSubject<String?, Never> { get }
}

struct DefaultTextInputTableViewCellViewModel: TextInputTableViewCellViewModel {
    var name: String
    var placeholder: String
    var value: CurrentValueSubject<String?, Never>
}
