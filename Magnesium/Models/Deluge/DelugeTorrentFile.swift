//
//  DelugeTorrentFile.swift
//  Magnesium
//
//  Created by James Hurst on 2020-01-08.
//  Copyright © 2020 James Hurst. All rights reserved.
//

struct DelugeTorrentFile {
    let name: String
    let index: Int
    let path: String
    let size: Int64
    let progress: Float
    let priority: Int
}

extension DelugeTorrentFile {
    init?(name: String, dictionary: [String: Any]) {
        guard let index = dictionary["index"] as? Int,
            let path = dictionary["path"] as? String,
            let size = dictionary["size"] as? Int64,
            let progress = dictionary["progress"] as? Float,
            let priority = dictionary["priority"] as? Int
        else {
            return nil
        }

        self.name = name
        self.index = index
        self.path = path
        self.size = size
        self.progress = progress
        self.priority = priority
    }
}
