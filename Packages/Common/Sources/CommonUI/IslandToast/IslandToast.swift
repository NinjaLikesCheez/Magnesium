//
//  IslandToast.swift
//  Magnesium
//
//  Created by ninji on 18/07/2026.
//

import SwiftUI

/// Item type driving an `.islandToast(item:)` presentation.
///
/// Only `Hashable` is required — unlike `PanelItem`, which needs `Identifiable` because
/// `.fullScreenCover(item:)` mandates it, the toast host is a plain `.overlay` and reacts to
/// item changes through `onChange`. Callers typically use a `@CasePathable enum` on the owning
/// `Model` (no `var id: Self { self }` boilerplate needed), matching the shape of feature
/// `Error` enums minus the `Identifiable` conformance.
public typealias IslandToastItem = Hashable

/// A bottom-anchored glass toast presentation.
///
/// Drives a non-blocking bottom-of-screen glass card that sits above tab/toolbar bar chrome
/// (the modifier's `.overlay(alignment: .bottom)` respects the container's safe-area insets,
/// so a tab bar naturally pushes the toast above it). A compact pill fades in first, then
/// morphs upward into an expanded card, holds for `duration`, and collapses back before
/// clearing. Deliberately non-blocking (SwiftUI overlay, not `fullScreenCover`) — it stacks
/// over ordinary content but call sites should attach the modifier on the screen/flow root
/// so nav chrome cannot compose over it. Not backed by ActivityKit; there is no Lock Screen
/// or Dynamic Island slot.
///
/// One card, one item — the third independent presentation surface alongside `destination`
/// (push) and `error` (`.panel(item:)`). See `documentation/navigation.md`.
public struct IslandToast<Item: IslandToastItem>: ViewModifier {
	@Binding private var item: Item?
	private let contentBuilder: (Item) -> IslandToastCard

	@Environment(\.userInterfaceIdiom) private var idiom

	/// Locally-owned card so the collapse animation can play after the caller sets `item = nil`,
	/// matching the internal-proxy pattern in `Panel` (which keeps its own `presentedItem` for
	/// the same reason).
	@State private var displayedCard: IslandToastCard?
	@State private var isExpanded = false
	/// Single task owning the whole choreography for the current `item` — expand delay, hold,
	/// auto-dismiss, or collapse. Cancelled + replaced on every `item` change so a rapid
	/// item-swap or dismiss-during-morph can't leave a stale delayed animation firing after the
	/// state it targeted is already gone.
	@State private var presentationTask: Task<Void, Never>?
	@Namespace private var glassNamespace

	/// Tuned to feel Island-like — short, snappy, low-damping-ish spring rather than a slow
	/// bouncy one.
	private let morphAnimation: Animation = .spring(response: 0.32, dampingFraction: 0.78)

	/// Delay between initial compact insertion and morph to expanded (phone only). Kept small so
	/// the compact pill reads as a single continuous grow-into-a-card, not a two-step banner.
	private let compactHoldDuration: Duration = .milliseconds(140)

	/// Time we allow the collapse-to-hidden transition to run before clearing `displayedCard`.
	/// Slightly longer than `morphAnimation.response` so the removal transition finishes visibly.
	private let dismissAnimationDuration: Duration = .milliseconds(320)

	public init(
		item: Binding<Item?>,
		contentBuilder: @escaping (Item) -> IslandToastCard
	) {
		self._item = item
		self.contentBuilder = contentBuilder
	}

	public func body(content: Content) -> some View {
		content
			.overlay(alignment: .bottom) {
				overlayHost
			}
			.onChange(of: item, initial: true) { _, newItem in
				handleItemChange(newItem)
			}
	}

	// MARK: Overlay

	@ViewBuilder
	private var overlayHost: some View {
		if let card = displayedCard {
			GlassEffectContainer {
				Group {
					if isExpanded {
						cardButton(card: card, phase: .expanded)
							.glassEffectID(Self.glassID, in: glassNamespace)
					} else {
						cardButton(card: card, phase: .compact)
							.glassEffectID(Self.glassID, in: glassNamespace)
					}
				}
				.transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
			}
			.padding(.bottom, bottomInset)
			.animation(morphAnimation, value: isExpanded)
		}
	}

	@ViewBuilder
	private func cardButton(card: IslandToastCard, phase: Phase) -> some View {
		Button {
			handleTap()
		} label: {
			switch phase {
			case .compact: card.compact
			case .expanded: card.expanded
			}
		}
		.buttonStyle(.plain)
		.disabled(phase == .compact)
		.accessibilityLabel(card.title)
		.accessibilityHint(card.subtitle ?? "")
	}

	/// Small gap between the card and whatever chrome (tab bar / bottom toolbar) or safe-area
	/// edge is directly beneath it. The overlay's default alignment already respects safe-area
	/// insets so a tab bar naturally pushes the toast above it; this padding just keeps the
	/// card from visually kissing that edge.
	private var bottomInset: CGFloat {
		switch idiom {
		case .phone: 8
		default: 12
		}
	}

	private enum Phase {
		case compact
		case expanded
	}

	/// Fixed id so both compact and expanded participate in the same glass morph.
	private static var glassID: String { "islandToast" }

	// MARK: State machine

	private func handleItemChange(_ newItem: Item?) {
		presentationTask?.cancel()

		guard let newItem else {
			guard displayedCard != nil else { return }
			presentationTask = Task { @MainActor in
				await runCollapse()
			}
			return
		}

		let card = contentBuilder(newItem)

		presentationTask = Task { @MainActor in
			await runPresentation(card: card)
		}
	}

	@MainActor
	private func runPresentation(card: IslandToastCard) async {
		displayedCard = card

		if idiom == .phone {
			isExpanded = false
			try? await Task.sleep(for: compactHoldDuration)
			guard !Task.isCancelled else { return }
			withAnimation(morphAnimation) { isExpanded = true }
		} else {
			withAnimation(morphAnimation) { isExpanded = true }
		}

		guard let duration = card.duration else { return }
		try? await Task.sleep(for: duration)
		guard !Task.isCancelled else { return }
		// Trigger a nil-item onChange → collapse path.
		item = nil
	}

	@MainActor
	private func runCollapse() async {
		if idiom == .phone {
			withAnimation(morphAnimation) { isExpanded = false }
			try? await Task.sleep(for: compactHoldDuration)
			guard !Task.isCancelled else { return }
		}
		withAnimation(morphAnimation) {
			displayedCard = nil
			isExpanded = false
		}
		try? await Task.sleep(for: dismissAnimationDuration)
	}

	private func handleTap() {
		displayedCard?.action?()
		item = nil
	}
}

public extension View {
	/// Presents a Dynamic-Island-style toast when `item` is non-nil.
	///
	/// The toast is a third independent presentation surface on a feature's `Model`, alongside
	/// `destination` (push) and `error` (`.panel`). See `documentation/navigation.md`.
	///
	/// - Parameters:
	///   - item: Source of truth. Setting non-nil presents; setting nil plays the collapse
	///     animation and dismisses.
	///   - content: Builds the `IslandToastCard` for a given item. Auto-dismiss `duration` and
	///     tap `action` live on the card; the modifier reads them from the built card.
	func islandToast<Item: IslandToastItem>(
		item: Binding<Item?>,
		content: @escaping (Item) -> IslandToastCard
	) -> some View {
		self.modifier(IslandToast(item: item, contentBuilder: content))
	}
}

// MARK: Preview

/// Mirrors the shape of a real feature `Toast` enum — a plain `@CasePathable` + `Hashable`
/// enum, no `Identifiable` conformance needed (see `IslandToastItem`).
private enum PreviewToast: Hashable {
	case recheckStarted
	case trackersUpdated
	case persistent
}

#Preview("IslandToast — inside NavigationStack with toolbar") {
	@Previewable @State var toast: PreviewToast?

	NavigationStack {
		List {
			Section("Trigger a toast") {
				Button("Recheck started (success, 3s)") { toast = .recheckStarted }
				Button("Trackers updated (info, 3s)") { toast = .trackersUpdated }
				Button("Persistent (tap to dismiss)") { toast = .persistent }
			}
		}
		.navigationTitle("Island Toast")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Button("Clear") { toast = nil }
			}
		}
	}
	.islandToast(item: $toast) { toast in
		switch toast {
		case .recheckStarted:
			IslandToastCard(
				title: "Recheck started",
				subtitle: "Verifying files against the tracker",
				role: .success
			)
		case .trackersUpdated:
			IslandToastCard(title: "Trackers updated", role: .info)
		case .persistent:
			IslandToastCard(
				title: "Long running task",
				subtitle: "Tap to dismiss",
				role: .warning,
				duration: nil
			)
		}
	}
}
