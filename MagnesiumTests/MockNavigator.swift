//
//  MockNavigator.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2019-12-20.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Foundation
@testable import Magnesium

final class SplitNavigator {
    lazy var master = MockNavigator(splitNavigator: self)
    lazy var detail = MockNavigator(splitNavigator: self)
}

final class MockNavigator: Navigator {
    private(set) weak var splitNavigator: SplitNavigator?
    private(set) var presentationStack: [MockPresentationContext]

    init(
        splitNavigator: SplitNavigator? = nil,
        presentationStack: [MockPresentationContext] = []
    ) {
        self.splitNavigator = splitNavigator
        self.presentationStack = presentationStack
    }

    func push(_ navigatable: Navigatable, animated: Bool) {
        presentationStack.last?.screens.append(navigatable)
    }

    func pop(animated: Bool) {
        presentationStack.last?.screens.removeLast()
    }

    func popToRoot(animated: Bool) {
        guard let first = presentationStack.first else { return }
        presentationStack = [first]
    }

    func present(_ navigatable: Navigatable, style: PresentationStyle, animated: Bool, completion: (() -> Void)? = nil) {
        presentationStack.append(MockPresentationContext(navigatable))
    }

    func dismiss(animated: Bool, completion: (() -> Void)?) {
        presentationStack.removeLast()
    }

    func showDetail(_ navigatable: Navigatable) {
        guard let splitNavigator = splitNavigator else { return }
        splitNavigator.detail = MockNavigator(splitNavigator: splitNavigator, presentationStack: [MockPresentationContext(navigatable)])
    }
}

final class MockPresentationContext {
    var screens = [Navigatable]()

    init(_ screen: Navigatable) {
        screens = [screen]
    }
}
