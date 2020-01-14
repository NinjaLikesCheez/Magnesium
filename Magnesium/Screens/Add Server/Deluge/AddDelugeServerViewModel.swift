//
//  AddDelugeServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-13.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Combine

protocol AddDelugeServerViewModel {
    var title: String { get }
    var saveButtonTitle: String { get }
    var isLoading: AnyPublisher<Bool, Never> { get }
    var isSaveButtonEnabled: AnyPublisher<Bool, Never> { get }
    var nameViewModel: TextInputTableViewCellViewModel { get }
    var serverViewModel: TextInputTableViewCellViewModel { get }
    var passwordViewModel: TextInputTableViewCellViewModel { get }
    func didSelectSave()
}
