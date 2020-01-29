//
//  ViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-28.
//  Copyright © 2020 James Hurst. All rights reserved.
//

/// A `ViewModel` is able to handle incoming view events and has a view state.
public protocol ViewModel {
    associatedtype ViewEvent
    associatedtype ViewState

    /// The view state. Any values that can change over time will be publishers in the view state.
    var state: ViewState { get }

    /// Handles an incoming view event.
    /// - Parameter event: The view event to be handled.
    func handle(_ event: ViewEvent)
}

public extension ViewModel where ViewEvent == Never {
    func handle(_ event: Never) {}
}
