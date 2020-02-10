//
//  LPLinkMetadata+Torrent.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-09.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import LinkPresentation

extension LPLinkMetadata {
    convenience init(torrent: StandardTorrent) {
        self.init()
        title = torrent.name

        let firstCharacter = (torrent.name.first.map { String($0) } ?? "") as NSString
        let iconProvider = NSItemProvider()
        iconProvider.registerObject(ofClass: UIImage.self, visibility: .all) { completion -> Progress? in
            let bounds = CGRect(x: 0, y: 0, width: 40, height: 40)
            let image = UIGraphicsImageRenderer(bounds: bounds).image { ctx in
                ctx.cgContext.setFillColor(UIColor.systemGray5.cgColor)
                ctx.fill(bounds)
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 20, weight: .medium),
                    .foregroundColor: UIColor.secondaryLabel,
                    .paragraphStyle: paragraphStyle,
                ]
                let size = firstCharacter.size(withAttributes: attributes)
                let frame = CGRect(
                    x: bounds.minX,
                    y: bounds.minY + (bounds.height - size.height) * 0.5,
                    width: bounds.size.width,
                    height: size.height
                )
                firstCharacter.draw(in: frame, withAttributes: attributes)
            }
            completion(image, nil)
            return nil
        }
        self.iconProvider = iconProvider
    }
}
