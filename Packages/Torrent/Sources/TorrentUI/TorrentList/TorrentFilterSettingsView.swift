import SwiftUI

struct TorrentFilterMenu: View {
	@Environment(TorrentPreferences.self) var preferences

	var labels: [StandardLabel]

	init(labels: [StandardLabel]) {
		self.labels = labels
	}

	var body: some View {
		Menu {
			filterMenu
			viewOptionsMenu
		} label: {
			Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
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
		Menu("State") {
			ForEach(StandardTorrentState.allCases) { state in
				Button {
					if preferences.filterOptions.states.contains(state) {
						preferences.filterOptions.states.remove(state)
					} else {
						preferences.filterOptions.states.insert(state)
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
				preferences.filterOptions.states = []
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
		Menu("Label") {
			ForEach(labels.sorted(by: { $0.name < $1.name }), id: \.self) { label in
				Button {
					if preferences.filterOptions.labels.contains(label.name) {
						preferences.filterOptions.labels.remove(label.name)
					} else {
						preferences.filterOptions.labels.insert(label.name)
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
		@Bindable var preferences = preferences

		return Menu("View Options") {
			Picker("Sort", selection: $preferences.sortOption.property) {
				ForEach(TorrentSortOption.Property.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)

			Picker("Direction", selection: $preferences.sortOption.direction) {
				ForEach(TorrentSortOption.Direction.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)
		}
	}
}
