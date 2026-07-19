//
//  IslandToastCard.swift
//  Magnesium
//
//  Created by ninji on 18/07/2026.
//

import SwiftUI

/// Content + styling for an `IslandToast` presentation.
///
/// A card carries all the primitives the modifier needs — text, symbol, role, `duration`
/// (auto-dismiss timing, `nil` = persistent until tap), and an optional `action` to run on tap.
/// The modifier reads these directly; it does not use the card's `body`. `body` renders the
/// expanded representation so a bare `IslandToastCard` still previews meaningfully in
/// `#Preview` blocks.
public struct IslandToastCard: View {
	/// Visual role — drives default tint + SF Symbol when no explicit `icon` is provided.
	public enum Role: Sendable, Hashable {
		case info
		case success
		case warning
		case error

		public var tint: Color {
			switch self {
			case .info: .accentColor
			case .success: .green
			case .warning: .yellow
			case .error: .red
			}
		}

		public var defaultSystemName: String {
			switch self {
			case .info: "info.circle.fill"
			case .success: "checkmark.circle.fill"
			case .warning: "exclamationmark.triangle.fill"
			case .error: "xmark.octagon.fill"
			}
		}
	}

	public let title: String
	public let subtitle: String?
	public let icon: String?
	public let role: Role
	public let duration: Duration?
	public let action: (() -> Void)?

	public init(
		title: String,
		subtitle: String? = nil,
		icon: String? = nil,
		role: Role = .info,
		duration: Duration? = .seconds(3),
		action: (() -> Void)? = nil
	) {
		self.title = title
		self.subtitle = subtitle
		self.icon = icon
		self.role = role
		self.duration = duration
		self.action = action
	}

	public var body: some View {
		expanded
	}

	/// SF Symbol to display — explicit override, or the role's default.
	var systemName: String {
		icon ?? role.defaultSystemName
	}

	/// Compact "island" pill — icon only, sized close to the idle Dynamic Island footprint.
	/// Not pixel-perfect vs the system island (no public API for those metrics); tuned to
	/// "reads as island."
	@ViewBuilder
	var compact: some View {
		Image(systemName: systemName)
			.font(.system(size: 18, weight: .semibold))
			.foregroundStyle(role.tint)
			.frame(width: 126, height: 37)
			.glassEffect(.regular, in: .capsule)
	}

	/// Expanded card — leading icon + title / optional subtitle. Grows downward from the same
	/// top anchor as `compact` so the glass morph reads as an expansion.
	@ViewBuilder
	var expanded: some View {
		HStack(spacing: 12) {
			Image(systemName: systemName)
				.font(.system(size: 24, weight: .semibold))
				.foregroundStyle(role.tint)
				.frame(width: 44, height: 44)

			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.font(.headline)
					.lineLimit(2)

				if let subtitle {
					Text(subtitle)
						.font(.subheadline)
						.foregroundStyle(.secondary)
						.lineLimit(3)
				}
			}

			Spacer(minLength: 0)
		}
		.padding(.horizontal, 16)
		.padding(.vertical, 12)
		.frame(maxWidth: 380)
		.glassEffect(.regular.interactive(), in: .rect(cornerRadius: 28, style: .continuous))
	}
}

#Preview("Expanded — info") {
	IslandToastCard(
		title: "Recheck started",
		subtitle: "Verifying files against the tracker",
		role: .info
	)
	.padding()
}

#Preview("Expanded — success (title only)") {
	IslandToastCard(title: "Tracker updated", role: .success)
		.padding()
}

#Preview("Compact — success") {
	IslandToastCard(title: "Tracker updated", role: .success)
		.compact
		.padding()
}
