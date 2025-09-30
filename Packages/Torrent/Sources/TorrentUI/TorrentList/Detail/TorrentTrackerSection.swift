//
//  TorrentTrackerSection.swift
//  Magnesium
//
//  Created by ninji on 10/04/2025.
//

import SwiftUI

struct TorrentTrackerSection: View {
	var torrent: StandardTorrent

	var body: some View {
		Section {
			ForEach(torrent.trackers, id: \.self) { tracker in
				Text(tracker)
			}
		} header: {
			Text("Trackers")
				.font(.headline)
		}
	}
}
