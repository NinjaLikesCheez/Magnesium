enum FilterItem {
    case sort(String)
    case state(String)
    case label(String)
}

extension FilterItem: Equatable {}
extension FilterItem: Hashable {}
