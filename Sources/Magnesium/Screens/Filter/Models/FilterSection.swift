struct FilterSection {
    let type: FilterSectionType
    var items: [FilterItem]
}

extension FilterSection: Equatable {}
extension FilterSection: Hashable {}
