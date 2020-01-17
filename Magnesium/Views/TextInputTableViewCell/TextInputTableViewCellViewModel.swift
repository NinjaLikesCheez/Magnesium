//
//  TextInputTableViewCellViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TextInputTableViewCellViewModel {
    var name: String { get }
    var placeholder: String { get }
    var value: CurrentValueSubject<String?, Never> { get }
    var isEnabled: AnyPublisher<Bool, Never> { get }
    var isSecure: Bool { get }
    var keyboardType: UIKeyboardType { get }
    var returnKeyType: UIReturnKeyType { get }
    var textContentType: UITextContentType? { get }
    var autocapitalizationType: UITextAutocapitalizationType { get }
}

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
