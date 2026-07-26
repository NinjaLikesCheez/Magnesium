import SonarrCore

/// Sonarr's operation set, abstracted behind a protocol purely for testability/mocking.
///
/// Unlike `TorrentClient`, there's no second backend to abstract over — Sonarr has exactly one
/// API — so there's only ever one production conformer (`SonarrAPIClient`) alongside
/// `NullSonarrClient`.
@MainActor
public protocol SonarrClient: AnyObject, Sendable {
	func refresh() async throws(SonarrClientError) -> [StandardSeries]
	func setMonitored(_ monitored: Bool, for series: StandardSeries) async throws(SonarrClientError)
	func triggerSearch(for series: StandardSeries) async throws(SonarrClientError)
	func remove(_ series: StandardSeries, deleteFiles: Bool) async throws(SonarrClientError)
}

/// Placeholder used before a server is configured.
public final class NullSonarrClient: SonarrClient {
	public init() {}

	public func refresh() async throws(SonarrClientError) -> [StandardSeries] {
		throw .nullImplementation
	}

	public func setMonitored(_ monitored: Bool, for series: StandardSeries) async throws(SonarrClientError) {
		throw .nullImplementation
	}

	public func triggerSearch(for series: StandardSeries) async throws(SonarrClientError) {
		throw .nullImplementation
	}

	public func remove(_ series: StandardSeries, deleteFiles: Bool) async throws(SonarrClientError) {
		throw .nullImplementation
	}
}
