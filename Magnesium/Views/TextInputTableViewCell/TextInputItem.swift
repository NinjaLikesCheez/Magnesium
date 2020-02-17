//
//  TextInputItem.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-12.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

struct TextInputItem {
    var name: String
    var placeholder: String
    var value: CurrentValueSubject<String?, Never>
    var isEnabled: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    var configuration: Configuration
}

extension TextInputItem {
    struct Configuration {
        var isSecure: Bool = false
        var keyboardType: UIKeyboardType = .default
        var returnKeyType: UIReturnKeyType = .default
        var autocapitalizationType: UITextAutocapitalizationType = .sentences
        var autocorrectionType: UITextAutocorrectionType = .default
        var textContentType: UITextContentType?

        static let `default` = Configuration()

        static let url = Configuration(
            keyboardType: .URL,
            autocapitalizationType: .none,
            autocorrectionType: .no,
            textContentType: .URL
        )

        static let username = Configuration(
            returnKeyType: .next,
            autocapitalizationType: .none,
            autocorrectionType: .no,
            textContentType: .username
        )

        static let password = Configuration(
            isSecure: true,
            textContentType: .password
        )

        func withReturnKeyType(_ returnKeyType: UIReturnKeyType) -> Configuration {
            var configuration = self
            configuration.returnKeyType = returnKeyType
            return configuration
        }
    }
}
