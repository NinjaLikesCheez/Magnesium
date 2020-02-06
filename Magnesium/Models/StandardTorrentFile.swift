//
//  StandardTorrentFile.swift
//  Magnesium
//
//  Created by James Hurst on 2020-02-03.
//  Copyright © 2020 James Hurst. All rights reserved.
//

protocol StandardTorrentFile {
    var index: Int { get }
    var name: String { get }
    var size: Int64 { get }
    var progress: Float { get }
}
