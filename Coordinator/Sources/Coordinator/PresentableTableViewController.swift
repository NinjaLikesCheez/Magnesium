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
    private let didDismissSubject = PassthroughSubject<Void, Never>()

    open var didDismiss: AnyPublisher<Void, Never> {
        return didDismissSubject.eraseToAnyPublisher()
    }

    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissedForCoordinator {
            didDismissSubject.send(())
            didDismissSubject.send(completion: .finished)
        }
    }
}
