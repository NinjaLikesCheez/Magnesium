import Combine

struct SettingsViewValues {
    var sections: AnyPublisher<[SettingsSection], Never>
}
