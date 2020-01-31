//
//  PreviewViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-30.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import ViewModel

#if DEBUG
    final class PreviewViewModel<ViewEvent, ViewState>: ViewModel {
        let state: ViewState

        init(state: ViewState) {
            self.state = state
        }

        func handle(_ event: ViewEvent) {}
    }
#endif
