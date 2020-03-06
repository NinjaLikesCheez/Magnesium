import Combine

struct ServerSettingsViewState {
    var title: String
    var saveButtonTitle: String
    var canDelete: Bool
    var isLoading: AnyPublisher<Bool, Never>
    var isSaveButtonEnabled: AnyPublisher<Bool, Never>
    var inputs: [TextInputItem]
}
