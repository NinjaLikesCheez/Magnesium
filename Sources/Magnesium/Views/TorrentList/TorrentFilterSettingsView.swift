import SwiftUI
import Torrent

// TODO: rename this (or get rid)
enum TorrentSortOption: String, CaseIterable {
	case dateAdded = "Date Added"
	case name = "Name"
	case downloadSpeed = "Download Speed"
	case uploadSpeed = "Upload Speed"
	case progress = "Progress"

	enum Direction: String, CaseIterable {
		case ascending = "Ascending"
		case descending = "Descending"

		var inverted: Self {
			switch self {
			case .ascending:
					.descending
			case .descending:
					.ascending
			}
		}
	}
}

struct TorrentFilterMenu: View {
	var labels: [StandardLabel]

	@State private var selectedStates: Set<StandardTorrentState> = []
	@State private var selectedLabels: Set<String> = []

	init(labels: [StandardLabel]) {
		self.labels = labels

		let filters = Current.preferences.filterOptions
		selectedLabels = filters.labels
		selectedStates = filters.states
	}

	var body: some View {
		Menu {
			filterMenu
			viewOptionsMenu
		} label: {
			Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
		}
		.onChange(of: Current.preferences.filterOptions.labels) { _, labels in
			selectedLabels = labels
		}
		.onChange(of: Current.preferences.filterOptions.states) { _, states in
			selectedStates = states
		}
		.onChange(of: selectedLabels) { _, labels in
			Current.preferences.filterOptions.labels = labels
		}
		.onChange(of: selectedStates) { _, states in
			Current.preferences.filterOptions.states = states
		}
	}

	var filterMenu: some View {
		Menu("Filter") {
			stateMenu
			labelMenu
		}
		.pickerStyle(.menu)
		.menuActionDismissBehavior(.disabled)
	}

	var stateMenu: some View {
		@Bindable var preferences = Current.preferences

		return Menu("State") {
			ForEach(StandardTorrentState.allCases) { state in
				Button {
					if selectedStates.contains(state) {
						selectedStates.remove(state)
					} else {
						selectedStates.insert(state)
					}
				} label: {
					HStack {
						if preferences.filterOptions.states.contains(state) {
							Image(systemName: "checkmark")
							Spacer()
						}
						Text(state.rawValue)
					}
				}
			}

			Divider()

			Button {
				selectedStates = []
			} label: {
				HStack {
					Text("All")
					Spacer()
					if preferences.filterOptions.states.isEmpty {
						Image(systemName: "checkmark")
							.foregroundStyle(.blue)
					}
				}
			}
		}
	}

	var labelMenu: some View {
		@Bindable var preferences = Current.preferences

		return Menu("Label") {
			ForEach(labels.sorted(by: { $0.name < $1.name }), id: \.self) { label in
				Button {
					if selectedLabels.contains(label.name) {
						selectedLabels.remove(label.name)
					} else {
						selectedLabels.insert(label.name)
					}
				} label: {
					Text(label.name)

					Spacer()

					if preferences.filterOptions.labels.contains(label.name) {
						Image(systemName: "checkmark")
					}
				}
			}

			Divider()

			Button {
				preferences.filterOptions.labels = []
			} label: {
				HStack {
					Text("All")
					Spacer()
					if preferences.filterOptions.labels.isEmpty {
						Image(systemName: "checkmark")
							.foregroundStyle(.blue)
					}
				}
			}
		}
	}

	var viewOptionsMenu: some View {
		@Bindable var preferences = Current.preferences

		return Menu("View Options") {
			Picker("Sort", selection: $preferences.sortOption.property) {
				ForEach(Torrent.TorrentSortOption.Property.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)

			Picker("Direction", selection: $preferences.sortOption.direction) {
				ForEach(Torrent.TorrentSortOption.Direction.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)
		}
	}
}
