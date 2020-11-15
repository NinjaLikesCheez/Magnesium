import Combine

struct ServerSettingsViewValues {
    var title: String
    var saveButtonTitle: String
    var canDelete: Bool
    var isLoading: UIPublisher<Bool>
    var isSaveButtonEnabled: UIPublisher<Bool>
    var inputs: [TextInputItem]
}
