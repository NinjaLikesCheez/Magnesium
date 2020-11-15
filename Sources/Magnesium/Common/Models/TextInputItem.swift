import Combine
import UIKit

struct TextInputItem {
    var name: String
    var placeholder: String
    var value: CurrentValueSubject<String?, Never>
    var isEnabled: UIPublisher<Bool> = .init(false)
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
    }
}

extension TextInputItem.Configuration {
    static let `default` = Self()

    static let url = Self(
        keyboardType: .URL,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .URL
    )

    static let username = Self(
        returnKeyType: .next,
        autocapitalizationType: .none,
        autocorrectionType: .no,
        textContentType: .username
    )

    static let password = Self(
        isSecure: true,
        textContentType: .password
    )

    func withReturnKeyType(_ returnKeyType: UIReturnKeyType) -> Self {
        var configuration = self
        configuration.returnKeyType = returnKeyType
        return configuration
    }
}
