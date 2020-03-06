struct FilterSection: Equatable {
    enum SectionType: Equatable {
        case sort
        case filters
    }

    let type: SectionType
    var items: [FilterItem]
}
