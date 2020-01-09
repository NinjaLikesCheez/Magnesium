//
//  TorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine
import UIKit

protocol TorrentDetailViewModel {
    var sections: AnyPublisher<[(TorrentDetailSection, [TorrentDetailItem])], Never> { get }
    func refresh() -> AnyPublisher<Never, Error>
    func pause()
    func resume()
    func remove()
}
