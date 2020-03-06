//
//  ServerSettingsViewState.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-05.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

struct ServerSettingsViewState {
    var title: String
    var saveButtonTitle: String
    var canDelete: Bool
    var isLoading: AnyPublisher<Bool, Never>
    var isSaveButtonEnabled: AnyPublisher<Bool, Never>
    var inputs: [TextInputItem]
}
