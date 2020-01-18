//
//  PresentableViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

open class PresentableViewController: UIViewController, Presentable {
    private let didDismissSubject = PassthroughSubject<Never, Never>()

    public var didDismiss: AnyPublisher<Never, Never> {
        return didDismissSubject.eraseToAnyPublisher()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissedForCoordinator {
            didDismissSubject.send(completion: .finished)
        }
    }
}
