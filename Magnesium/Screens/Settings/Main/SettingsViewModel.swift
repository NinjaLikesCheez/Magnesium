//
//  SettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-14.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol SettingsViewModel {
    var servers: AnyPublisher<[(id: AnyHashable, name: String)], Never> { get }
    func didSelectClose()
    func didSelectServer(at index: Int)
    func didSelectAddServer()
}
