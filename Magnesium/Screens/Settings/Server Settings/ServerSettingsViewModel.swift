//
//  ServerSettingsViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-17.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol ServerSettingsViewModel {
    var title: String { get }
    var saveButtonTitle: String { get }
    var canDelete: Bool { get }
    var isLoading: AnyPublisher<Bool, Never> { get }
    var isSaveButtonEnabled: AnyPublisher<Bool, Never> { get }
    var inputs: [TextInputTableViewCellViewModel] { get }
    func didSelectSave()
    func didSelectDelete(from source: PopoverSource)
}
