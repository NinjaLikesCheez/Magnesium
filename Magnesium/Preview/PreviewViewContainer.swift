//
//  PreviewViewContainer.swift
//  Magnesium
//
//  Created by James Hurst on 2019-12-19.
//  Copyright © 2019 James Hurst. All rights reserved.
//

import UIKit

#if DEBUG
    class PreviewViewContainer<T: UIView>: UIView {
        let inner: T
        let width: CGFloat

        override var intrinsicContentSize: CGSize {
            CGSize(
                width: width,
                height: inner.systemLayoutSizeFitting(CGSize(
                    width: width,
                    height: CGFloat.greatestFiniteMagnitude
                )).height
            )
        }

        init(_ view: T, width: CGFloat = 320) {
            inner = view
            self.width = width
            super.init(frame: .zero)
            backgroundColor = .systemBackground
            addSubview(view)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            inner.frame = bounds
        }
    }
#endif
