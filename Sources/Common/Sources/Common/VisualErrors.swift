import Deluge
import Foundation

public protocol VisualError: Error, Equatable, Hashable {
	var title: String { get }
	var systemName: String { get }
	var subtitle: String { get }
}

