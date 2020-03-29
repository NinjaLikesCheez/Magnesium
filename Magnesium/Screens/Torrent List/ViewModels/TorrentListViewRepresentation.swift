import Combine

struct TorrentListViewRepresentation {
    var showAddButton: Bool = true
    var showFilterButton: Bool = true
    var title: AnyPublisher<String, Never>
    var items: AnyPublisher<[TorrentListItem], Never>
    var isLoading: AnyPublisher<Bool, Never>
    var isEditing: AnyPublisher<Bool, Never>
    var hasActiveFilters: AnyPublisher<Bool, Never>
    var editActionsEnabled: AnyPublisher<Bool, Never>
    var status: AnyPublisher<String, Never>
}
