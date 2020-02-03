//
//  TransmissionTorrentDetailHeaderViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-02.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit
import ViewModel

struct TransmissionTorrentDetailHeaderViewModel: ViewModel, Identifiable {
    private let hash: String
    let state: TorrentDetailHeaderViewState

    var id: String {
        return hash
    }

    init(subject: CurrentValueSubject<TransmissionTorrent, Never>) {
        hash = subject.value.hash
        let ui = subject.ui()
        state = TorrentDetailHeaderViewState(
            name: ui.map(\.name).eraseToAnyPublisher(),
            isActive: ui.map(\.isActive).eraseToAnyPublisher(),
            progress: ui.map(\.progress).eraseToAnyPublisher(),
            progressColor: ui.map(\.commonState).map(\.displayColor).eraseToAnyPublisher(),
            status: ui
                .map { "\($0.commonState.displayString) (\(String(format: "%.2f", $0.progress * 100))%)" }
                .eraseToAnyPublisher()
        )
    }
}
