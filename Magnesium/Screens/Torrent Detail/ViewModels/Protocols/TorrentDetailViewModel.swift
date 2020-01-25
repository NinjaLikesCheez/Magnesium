//
//  TorrentDetailViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2019-11-16.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import Combine

enum TorrentDetailEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}

protocol TorrentDetailViewModel {
    var events: AnyPublisher<TorrentDetailEvent, Never> { get }
    var sections: AnyPublisher<[TorrentDetailSection], Never> { get }
    func didAppear()
    func didDisappear()
    func refresh() -> AnyPublisher<Void, Error>
    func didSelectMoreOptions(from source: PopoverSource)
    func didSelectPause()
    func didSelectResume()
    func didSelectRemove(from source: PopoverSource)
}
