import CommonModels

enum ServerSettingsViewEvent {
    case saveSelected
    case deleteSelected(source: PopoverSource)
    case cancelSelected
}
