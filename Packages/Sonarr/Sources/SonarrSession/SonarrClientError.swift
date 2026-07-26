import Sonarr

public enum SonarrClientError: Error {
	/// Thrown by the Null Implementation (used before a server is configured; should not happen in production).
	case nullImplementation

	case sonarr(Sonarr.Error)
}
