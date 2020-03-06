import Combine

struct TorrentListViewState {
    var showAddButton: Bool = true
    var showFilterButton: Bool = true
    var title: AnyPublisher<String, Never>
    var items: AnyPublisher<[TorrentListItem], Never>
    var isLoading: AnyPublisher<Bool, Never>
    var hasActiveFilters: AnyPublisher<Bool, Never>
    var editActionsEnabled: AnyPublisher<Bool, Never>
    var totalDownloadSpeed: AnyPublisher<String, Never>
    var totalUploadSpeed: AnyPublisher<String, Never>
}
