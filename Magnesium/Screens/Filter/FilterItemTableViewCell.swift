//
//  FilterItemTableViewCell.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import UIKit

final class FilterItemTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
