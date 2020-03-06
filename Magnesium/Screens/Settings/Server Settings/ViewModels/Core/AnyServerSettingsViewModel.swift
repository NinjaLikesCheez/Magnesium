//
//  AnyServerSettingsViewModel.swift
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
