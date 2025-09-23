import Deluge
import QBittorrent

public enum TorrentClientError: Error {
	/// Represents an error thrown by the Null Implementation (a testing implementation, this should not happen in production)
	case nullImplementation

	case invalidLinkAdded

	case deluge(Deluge.Error)

	case qbittorrent(QBittorrent.Error)
}
