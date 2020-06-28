import CommonModels

enum SettingsViewEvent {
    case doneSelected
    case changeServerSelected(source: PopoverSource)
    case serverSelected(index: Int)
    case addServerSelected
    case refreshIntervalSelected
}
