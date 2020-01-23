//
//  TorrentListViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

protocol TorrentListViewModel: AnyObject {
    var observers: [AnyCancellable] { get set }
    var showAddButton: Bool { get }
    var coordinator: TorrentListCoordinator? { get }
    var items: AnyPublisher<[AnyTorrentListItemViewModel], Never> { get }

    func refresh() -> AnyPublisher<Void, Error>
    func didSelectSettings()
    func didSelectAdd()
    func didSelectItem(at index: Int)
    func addLink(_ url: String)
}

extension TorrentListViewModel {
    var showAddButton: Bool {
        return true
    }

    func didSelectSettings() {
        coordinator?.showSettings()
    }

    func didSelectAdd() {
        var alert = Alert(title: "Add Torrent", message: "How would you like to add the torrent?", style: .actionSheet)
        alert.addAction(AlertAction(title: "Add Link", style: .default) {
            self.coordinator?.showAddLink()
                .sink(receiveValue: { [weak self] url in
                    self?.addLink(url)
                })
                .store(in: &self.observers)
        })
        alert.addAction(AlertAction(title: "Add File", style: .default) {
            // TODO:
        })
        alert.addAction(AlertAction(title: "Cancel", style: .cancel))
        coordinator?.showAlert(alert)
    }
}
