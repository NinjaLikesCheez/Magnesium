import Foundation

extension L10n.Screen {
	enum Filter {
		static var title: String {
			NSLocalizedString("screen.filter.title", comment: "Filter")
		}

		static var filteredAll: String {
			NSLocalizedString("screen.filter.filtered-all", comment: "All")
		}

		static var state: String {
			NSLocalizedString("screen.filter.state-filter", comment: "State")
		}

		static var label: String {
			NSLocalizedString("screen.filter.label-filter", comment: "Label")
		}

		static var sortBy: String {
			NSLocalizedString("screen.filter.sort-by", comment: "Sort by")
		}

		static var sortByHint: String {
			NSLocalizedString(
				"screen.filter.sort-by-hint",
				comment: "Select the current sort option to sort in the opposite direction."
			)
		}

		static var filterByLabel: String {
			NSLocalizedString("screen.filter.filter-by-label", comment: "Filter by Label")
		}

		static var filterByLabelHint: String {
			NSLocalizedString(
				"screen.filter.filter-by-label-hint",
				comment: "Only display torrents with the selected label."
			)
		}

		static var filterByState: String {
			NSLocalizedString("screen.filter.filter-by-state", comment: "Filter by State")
		}

		static var filterByStateHint: String {
			NSLocalizedString(
				"screen.filter.filter-by-state-hint",
				comment: "Only display torrents with the selected state."
			)
		}
	}
}
