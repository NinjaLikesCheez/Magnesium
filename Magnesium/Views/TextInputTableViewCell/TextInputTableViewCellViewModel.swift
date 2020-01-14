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
    let name: String
    let placeholder: String
    let value: CurrentValueSubject<String?, Never>
    let isEnabledSubject: CurrentValueSubject<Bool, Never>
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    let returnKeyType: UIReturnKeyType
    let textContentType: UITextContentType?
    let autocapitalizationType: UITextAutocapitalizationType

    var isEnabled: AnyPublisher<Bool, Never> {
        return isEnabledSubject
            .ui()
            .eraseToAnyPublisher()
    }

    init(
        name: String,
        placeholder: String,
        value: CurrentValueSubject<String?, Never>,
        isEnabled: CurrentValueSubject<Bool, Never> = CurrentValueSubject(true),
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        returnKeyType: UIReturnKeyType = .default,
        textContentType: UITextContentType? = nil,
        autocapitalizationType: UITextAutocapitalizationType = .sentences
    ) {
        self.name = name
        self.placeholder = placeholder
        self.value = value
        isEnabledSubject = isEnabled
        self.isSecure = isSecure
        self.keyboardType = keyboardType
        self.returnKeyType = returnKeyType
        self.textContentType = textContentType
        self.autocapitalizationType = autocapitalizationType
    }
}
