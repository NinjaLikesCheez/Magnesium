//
//  MockPresentableViewController.swift
//  MagnesiumTests
//
//  Created by James Hurst on 2020-02-04.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Coordinator
import UIKit

open class MockPresentableViewController: PresentableViewController {
    private(set) var presentCallCount = 0
    private(set) var presentParamViewController = [UIViewController]()
    private(set) var presentParamAnimated = [Bool]()
    override open func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        super.present(viewController, animated: flag, completion: completion)
        presentCallCount += 1
        presentParamViewController.append(viewControllerToPresent)
        presentParamAnimated.append(flag)
    }

    private(set) var dismissCallCount = 0
    private(set) var dismissParamAnimated = [Bool]()
    override open func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        dismissCallCount += 1
        dismissParamAnimated.append(flag)
    }
}
