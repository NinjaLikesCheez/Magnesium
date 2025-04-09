import SwiftUI

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

struct TorrentFilterSettingsView: View {
	@Environment(Session.self) private var session: Session

	let labels: [StandardLabel]

	@State private var selectedSortProperty: SortOption.Property
	@State private var selectedSortDirection: SortOption.Direction
	
	@State private var selectedStates: Set<TorrentState>
	@State private var selectedLabels: Set<String>

	init(labels: [StandardLabel]) {
		self.labels = labels

		let filters = Current.preferences.filterOptions
		selectedLabels = filters.labels
		selectedStates = filters.states

		let sortOption = Current.preferences.sortOption
		selectedSortProperty = sortOption.property
		selectedSortDirection = sortOption.direction
	}

	var body: some View {
		NavigationStack {
			List {
				sortSection

				generalSection

				Button("Reset", role: .destructive) {
					reset()
				}
				.frame(maxWidth: .infinity, alignment: .center)
			}
			.navigationTitle("Filter")
			.navigationBarTitleDisplayMode(.inline)
			.onChange(of: selectedLabels) { _, newValue in
				Current.preferences.filterOptions.labels = newValue
			}
			.onChange(of: selectedStates) { _, newValue in
				Current.preferences.filterOptions.states = newValue
			}
			.onChange(of: selectedSortProperty) { _, newValue in
				Current.preferences.sortOption.property = newValue
			}
			.onChange(of: selectedSortDirection) { _, newValue in
				Current.preferences.sortOption.direction = newValue
			}
		}
	}

	private func reset() {
		selectedSortProperty = .dateAdded
		selectedSortDirection = .descending
		selectedStates = []
		selectedLabels = []
	}

	var sortSection: some View {
		Section {
			Picker("Sort", selection: $selectedSortProperty) {
				ForEach(SortOption.Property.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)
			.accentColor(.secondary)

			Picker("Direction", selection: $selectedSortDirection) {
				ForEach(SortOption.Direction.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)
			.accentColor(.secondary)
		}
	}

	var generalSection: some View {
		Section {
			stateRow
			labelRow
		}
	}

	var stateRow: some View {
		HStack {
			Menu {
				Button {
					selectedStates = []
				} label: {
					HStack {
						Text("All")
						Spacer()
						if selectedStates.isEmpty {
							Image(systemName: "checkmark")
								.foregroundStyle(.blue)
						}
					}
				}

				// The rest of the states
				ForEach(TorrentState.allCases, id: \.self) { state in
					Button {
						if selectedStates.contains(state) {
							selectedStates.remove(state)
						} else {
							selectedStates.insert(state)
						}
					} label: {
						HStack {
							Text(state.rawValue)
							Spacer()
							if selectedStates.contains(state) {
								Image(systemName: "checkmark")
									.foregroundStyle(.blue)
							}
						}
					}
				}
			} label: {
				Text("State")

				Spacer()
				if selectedStates.isEmpty {
					Text("All")
						.foregroundStyle(.secondary)
				} else {
					Text(selectedStates.map(\.rawValue).joined(separator: ", "))
						.lineLimit(1)
						.foregroundStyle(.secondary)
				}
			}
			.menuActionDismissBehavior(.disabled)
			.foregroundStyle(.primary)
		}
	}

	var labelRow: some View {
		HStack {
			Menu {
				Button {
					selectedLabels = []
				} label: {
					HStack {
						Text("All")
						Spacer()
						if selectedLabels.isEmpty {
							Image(systemName: "checkmark")
								.foregroundStyle(.blue)
						}
					}
				}

				// The rest of the states
				ForEach(labels.sorted(by: { $0.name < $1.name }), id: \.self) { label in
					Button {
						if selectedLabels.contains(label.name) {
							selectedLabels.remove(label.name)
						} else {
							selectedLabels.insert(label.name)
						}
					} label: {
						HStack {
							Text(label.name)
							Spacer()
							if selectedLabels.contains(label.name) {
								Image(systemName: "checkmark")
									.foregroundStyle(.blue)
							}
						}
					}
				}
			} label: {
				Text("Label")
				Spacer()
				if selectedLabels.isEmpty {
					Text("All")
						.foregroundStyle(.secondary)
				} else {
					Text(selectedLabels.joined(separator: ", "))
						.lineLimit(1)
						.foregroundStyle(.secondary)
				}
			}
		}
		.menuActionDismissBehavior(.disabled)
		.foregroundStyle(.primary)
	}
}

#Preview {
	TorrentFilterSettingsView(
		labels: [
			.init(name: "MyLabel", count: 1),
			.init(name: "SecondLabel", count: 2),
		]
	)
	.environment(Session())
}
