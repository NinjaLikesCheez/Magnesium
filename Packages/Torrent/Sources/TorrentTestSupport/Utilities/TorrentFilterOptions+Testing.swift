import TorrentCore

extension TorrentFilterOptions {
	init(states: Set<StandardTorrentState> = [], labels: Set<String> = []) {
		self.init()
		self.states = states
		self.labels = labels
	}
}
