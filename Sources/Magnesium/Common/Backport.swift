//https://davedelong.com/blog/2021/10/09/simplifying-backwards-compatibility-in-swift/
import SwiftUI

public struct Backport<Content> {
	public let content: Content

	public init(_ content: Content) {
		self.content = content
	}
}

extension View {
	var backport: Backport<Self> { Backport(self) }
}

extension Backport where Content: View {
	@ViewBuilder func glassButtonStyle() -> some View {
		if #available(iOS 26.0, macOS 26.0, tvOS 26.0, visionOS 26.0, *) {
			content
				.buttonStyle(.glass)
		} else {
			content
		}
	}
}
