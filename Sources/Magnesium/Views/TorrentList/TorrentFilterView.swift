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

struct TorrentFilterView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(Session.self) private var session: Session

	let labels: [StandardLabel]

	@Binding private var selectedSortOption: TorrentSortOption
	@Binding private var sortDirection: TorrentSortOption.Direction
	@Binding private var selectedStates: Set<TorrentState>
	@Binding private var selectedLabels: Set<StandardLabel>

	var allStatesSelected: Bool {
		selectedStates.count == TorrentState.allCases.count
	}

	var allLabelsSelected: Bool {
		selectedLabels.count == labels.count || selectedLabels.isEmpty
	}

	init(
		labels: [StandardLabel],
		selectedSortOption: Binding<TorrentSortOption>,
		sortDirection: Binding<TorrentSortOption.Direction>,
		selectedStates: Binding<Set<TorrentState>>,
		selectedLabels: Binding<Set<StandardLabel>>
	) {
		self.labels = labels
		self._selectedSortOption = selectedSortOption
		self._sortDirection = sortDirection
		self._selectedStates = selectedStates
		self._selectedLabels = selectedLabels
	}

	var body: some View {
		NavigationStack {
			List {
				sortSection

				generalSection
			}
			.navigationTitle("Filter")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}

				ToolbarItem(placement: .topBarLeading) {
					Button("Reset") {
						selectedSortOption = .dateAdded
						sortDirection = .descending
						selectedStates = Set(TorrentState.allCases)
						selectedLabels = Set(labels)
					}
				}
			}
		}
	}

	var sortSection: some View {
		Section {
			Picker("Sort", selection: $selectedSortOption) {
				ForEach(TorrentSortOption.allCases, id: \.self) { option in
					Text(option.rawValue)
				}
			}
			.pickerStyle(.menu)
			.accentColor(.secondary)

			Picker("Direction", selection: $sortDirection) {
				ForEach(TorrentSortOption.Direction.allCases, id: \.self) { option in
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

	private func didSelectState(_ state: TorrentState) {
		if allStatesSelected {
			selectedStates.removeAll()
			selectedStates.insert(state)
		} else if selectedStates.contains(state) {
			selectedStates.remove(state)
		} else {
			selectedStates.insert(state)
		}

		// If all states are deselected, then apply 'all'
		if selectedStates.isEmpty {
			selectedStates = Set(TorrentState.allCases)
		}
	}

	private func didSelectLabel(_ label: StandardLabel) {
		if allLabelsSelected {
			selectedLabels.removeAll()
			selectedLabels.insert(label)
		} else if selectedLabels.contains(label) {
			selectedLabels.remove(label)
		} else {
			selectedLabels.insert(label)
		}

		// If all states are deselected, then apply 'all'
		if selectedLabels.isEmpty {
			selectedLabels = Set(labels)
		}
	}

	var stateRow: some View {
		HStack {
			Menu {
				Button {
					selectedStates = allStatesSelected ? [] : Set(TorrentState.allCases)
				} label: {
					HStack {
						Text("All")
						Spacer()
						if selectedStates.count == TorrentState.allCases.count {
							Image(systemName: "checkmark")
								.foregroundStyle(.blue)
						}
					}
				}

				// The rest of the states
				ForEach(TorrentState.allCases, id: \.self) { state in
					Button {
						didSelectState(state)
					} label: {
						HStack {
							Text(state.rawValue)
							Spacer()
							if selectedStates.contains(state) && !allStatesSelected {
								Image(systemName: "checkmark")
									.foregroundStyle(.blue)
							}
						}
					}
				}
			} label: {
				Text("State")

				Spacer()
				if allStatesSelected {
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
					selectedLabels = allLabelsSelected ? [] : Set(labels)
				} label: {
					HStack {
						Text("All")
						Spacer()
						if allLabelsSelected {
							Image(systemName: "checkmark")
								.foregroundStyle(.blue)
						}
					}
				}

				// The rest of the states
				ForEach(labels.sorted(by: { $0.name < $1.name }), id: \.self) { label in
					Button {
						didSelectLabel(label)
					} label: {
						HStack {
							Text(label.name)
							Spacer()
							if selectedLabels.contains(label) && !allLabelsSelected {
								Image(systemName: "checkmark")
									.foregroundStyle(.blue)
							}
						}
					}
				}
			} label: {
				Text("Label")
				Spacer()
				if allLabelsSelected {
					Text("All")
						.foregroundStyle(.secondary)
				} else {
					Text(selectedLabels.map(\.name).joined(separator: ", "))
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
	TorrentFilterView(
		labels: [
			.init(name: "MyLabel", count: 1),
			.init(name: "SecondLabel", count: 2),
		],
		selectedSortOption: .constant(.dateAdded),
		sortDirection: .constant(.descending),
		selectedStates: .constant(Set(TorrentState.allCases)),
		selectedLabels: .constant([])
	)
	.environment(Session())
}
