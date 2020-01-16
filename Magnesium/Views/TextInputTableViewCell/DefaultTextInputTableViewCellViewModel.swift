//
//  DefaultTextInputTableViewCellViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct DefaultTextInputTableViewCellViewModel: TextInputTableViewCellViewModel {
    var name: String
    var placeholder: String
    var value: CurrentValueSubject<String?, Never>
    var isEnabled: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var textContentType: UITextContentType?
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
}
