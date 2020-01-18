//
//  PresentableTableViewController.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine
import UIKit

open class PresentableTableViewController: UITableViewController, Presentable {
    private let didDismissSubject = PassthroughSubject<Never, Never>()

    open var didDismiss: AnyPublisher<Never, Never> {
        return didDismissSubject.eraseToAnyPublisher()
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissedForCoordinator {
            didDismissSubject.send(completion: .finished)
        }
    }
}
