//
//  AddServerViewModel.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-15.
//  Copyright © 2020 James Hurst. All rights reserved.
//

protocol AddServerViewModel {
    var types: [String] { get }
    func didSelectType(at index: Int)
}
