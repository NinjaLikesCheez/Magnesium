//
//  TorrentListViewState.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-12.
//  Copyright © 2019 James Hurst. All rights reserved.
//

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
