enum ServerType: String {
    case deluge
    case transmission
}

extension ServerType {
    var localizedString: String {
        switch self {
        case .deluge:
            return L10n.deluge
        case .transmission:
            return L10n.transmission
        }
    }
}

extension ServerType: Codable {}
