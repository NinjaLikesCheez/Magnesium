import Observation
import SwiftUINavigation

/// Navigation + presentation state for the TorrentDetail screen.
@Observable
public final class TorrentDetailModel {
	public var destination: Destination?
	public var error: Error?

	public init() {}
}

extension TorrentDetailModel {
	/// Stack-navigation targets for the TorrentDetail screen. Currently a leaf with nothing to
	/// push, but kept alongside `Error` for consistency with `TorrentListModel`'s shape.
	@CasePathable
	public enum Destination: Hashable {}

	/// Modal error presentations for the TorrentDetail screen.
	@CasePathable
	public enum Error: Hashable {
		case clientError(TorrentClientError)
	}
}
