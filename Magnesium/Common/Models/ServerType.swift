enum ServerType: String, Codable {
    case deluge
    case transmission

    var localizedString: String {
        switch self {
        case .deluge:
            return L10n.deluge
        case .transmission:
            return L10n.transmission
        }
    }
}
