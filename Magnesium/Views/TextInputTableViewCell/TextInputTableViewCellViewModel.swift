//
//  TextInputTableViewCellViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct TextInputTableViewCellViewState {
    var name: String
    var placeholder: String
    var value: CurrentValueSubject<String?, Never>
    var isEnabled: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    var configuration: TextInputConfiguration
}

struct TextInputConfiguration {
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var returnKeyType: UIReturnKeyType = .default
    var autocapitalizationType: UITextAutocapitalizationType = .sentences
    var autocorrectionType: UITextAutocorrectionType = .default
    var textContentType: UITextContentType?

    static let `default` = TextInputConfiguration()

    static let url = TextInputConfiguration(
        keyboardType: .URL,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .URL
    )

    static let username = TextInputConfiguration(
        returnKeyType: .next,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .username
    )

    static let password = TextInputConfiguration(
        isSecure: true,
        textContentType: .password
    )

    func withReturnKeyType(_ returnKeyType: UIReturnKeyType) -> TextInputConfiguration {
        var configuration = self
        configuration.returnKeyType = returnKeyType
        return configuration
    }
}
