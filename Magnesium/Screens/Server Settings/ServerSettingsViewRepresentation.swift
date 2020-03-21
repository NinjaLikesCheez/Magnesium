import Combine

struct ServerSettingsViewRepresentation {
    var title: String
    var saveButtonTitle: String
    var canDelete: Bool
    var isLoading: AnyPublisher<Bool, Never>
    var isSaveButtonEnabled: AnyPublisher<Bool, Never>
    var inputs: [TextInputItem]
}
