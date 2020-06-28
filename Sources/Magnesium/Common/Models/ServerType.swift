enum ServerType: String {
    case deluge
    case transmission
}

extension ServerType {
    var localizedString: String {
        switch self {
        case .deluge:
            return L10n.Server.deluge
        case .transmission:
            return L10n.Server.transmission
        }
    }
}

extension ServerType: Codable {}
