import CommonModels

enum SettingsViewModelEvent {
    case complete
    case alert(Alert)
    case editServer(Server)
    case addServer
    case showRefreshIntervalSettings
}
