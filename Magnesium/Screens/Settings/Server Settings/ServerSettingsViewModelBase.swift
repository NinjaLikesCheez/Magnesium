//
//  ServerSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import ViewModel

typealias AnyServerSettingsViewModel = AnyEmitterViewModel<
    ServerSettingsEvent,
    ServerSettingsViewEvent,
    ServerSettingsViewState
>

enum ServerSettingsEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}

enum ServerSettingsViewEvent {
    case save
    case delete(source: PopoverSource)
}

struct ServerSettingsViewState {
    var title: String
    var saveButtonTitle: String
    var canDelete: Bool
    var isLoading: AnyPublisher<Bool, Never>
    var isSaveButtonEnabled: AnyPublisher<Bool, Never>
    var inputs: [TextInputTableViewCellViewState]
}
