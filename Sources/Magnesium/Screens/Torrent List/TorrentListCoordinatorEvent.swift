enum TorrentListCoordinatorEvent {
    case showDetail(viewModel: AnyTorrentDetailViewModel)
    case commitDetail(coordinator: TorrentDetailCoordinator)
    case showSettings
    case torrentsUpdated(hashes: [String])
}
