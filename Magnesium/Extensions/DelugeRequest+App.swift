//
//  DelugeRequest+App.swift
//  Magnesium
//
//  Created by James Hurst on 2020-03-01.
//  Copyright © 2020 James Hurst. All rights reserved.
//

import Deluge

extension Deluge.Request where Value == ([DelugeTorrent], [DelugeLabel]) {
    private static let properties = [
        "name",
        "state",
        "time_added",
        "download_payload_rate",
        "upload_payload_rate",
        "eta",
        "progress",
        "total_done",
        "total_uploaded",
        "total_size",
        "num_seeds",
        "total_seeds",
        "num_peers",
        "total_peers",
        "trackers",
        "label",
        "download_location",
    ]

    static var currentStateForApp: Self {
        Request<([Deluge.Torrent], [Deluge.Label])>.currentState(properties: properties)
            .map { ($0.compactMap(DelugeTorrent.init), $1) }
    }
}
