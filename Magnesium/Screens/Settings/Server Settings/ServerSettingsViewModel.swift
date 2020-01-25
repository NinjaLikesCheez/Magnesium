//
//  ServerSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

enum ServerSettingsEvent {
    case complete
    case alert(Alert, source: PopoverSource?)
}

protocol ServerSettingsViewModel {
    var events: AnyPublisher<ServerSettingsEvent, Never> { get }
    var title: String { get }
    var saveButtonTitle: String { get }
    var canDelete: Bool { get }
    var isLoading: AnyPublisher<Bool, Never> { get }
    var isSaveButtonEnabled: AnyPublisher<Bool, Never> { get }
    var inputs: [TextInputTableViewCellViewModel] { get }
    func didSelectSave()
    func didSelectDelete(from source: PopoverSource)
}
