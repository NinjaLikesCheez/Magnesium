//
//  Panel.swift.swift
//  Magnesium
//
//  Created by ninji on 09/07/2025.
//

/* Based on https://github.com/reddavis/Panel/ */

// MIT License
//
// Copyright (c) 2022 Red Davis
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import SwiftUI

public typealias PanelItem = Identifiable & Equatable

/// A panel UI component.
public struct Panel<Item: PanelItem, PanelContent: View>: ViewModifier {
	// Private
	@Binding private var item: Item?
	private let contentBuilder: (_ item: Item) -> PanelContent
	private let onCancel: (() -> Void)?

	@State private var content: AnyView = .init(EmptyView())
	@State private var panelHeight = 0.0
	@State private var isPresented = false
	@State private var panelOpenAnimationProgress = 0.0
	@State private var offset = CGSize.zero

	private var panelSpringResponse: Double {
		isPresented ? 0.25 : 0.15
	}

	private var backgroundAnimationDuration: Double {
		isPresented ? 0.25 : 0.15
	}

	// MARK: Initialization

	/// Initialize a new instance of `Panel`
	/// - Parameters:
	///   - isPresented: A binding that determines whether the panel is presented or not.
	///   - onCancel: A closure called when the panel is cancelled. When this is not nil a cancel
	///   button will be added to the panel.
	///   - contentBuilder: A closure returning the content of the panel.
	public init(
		item: Binding<Item?>,
		onCancel: (() -> Void)? = nil,
		@ViewBuilder contentBuilder: @escaping (_ item: Item) -> PanelContent
	) {
		self._item = item
		self._isPresented = State(initialValue: item.wrappedValue != nil)
		self.contentBuilder = contentBuilder
		self.onCancel = onCancel
	}

	// MARK: Body

	public func body(content: Content) -> some View {
		ZStack {
			content

			ZStack(alignment: .bottom) {
				background()
				panelContent()
					// Inset it to look more like the system panel
					.padding([.leading, .trailing, .bottom], 15)
			}
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.onChange(of: self.item) { _, item in
				if let item {
					// If currently presented, recompute the content
					if self.isPresented {
						self.content = AnyView(contentBuilder(item))
					} else {
						presentPanel(for: item)
					}
				} else {
					closePanel()
				}
			}
		}
		.onAnimationCompletion(with: self.panelOpenAnimationProgress) {
			guard let item = self.item,
				!self.isPresented
			else { return }
			self.presentPanel(for: item)
		}
	}

	// MARK: Panel management

	private func presentPanel(for item: Item) {
		self.content = AnyView(self.contentBuilder(item))

		Task {
			withAnimation {
				self.isPresented = true
				self.panelOpenAnimationProgress = 1.0
			}
		}
	}

	private func closePanel() {
		withAnimation {
			self.isPresented = false
			self.panelOpenAnimationProgress = 0.0
		}
	}

	// MARK: UI

	private func background() -> some View {
		Group {
			if isPresented {
				Color.black.opacity(0.8)
					.ignoresSafeArea()
					.transition(
						.opacity.animation(
							.easeInOut(duration: backgroundAnimationDuration)
						)
					)
			}
		}
	}

	private func panelContent() -> some View {
		GeometryReader { proxy in
			ZStack(alignment: .topTrailing) {
				content
					.padding(EdgeInsets(top: 32.0, leading: 24.0, bottom: 32.0, trailing: 24.0))

				if let onCancel {
					Button(
						action: {
							item = nil
							onCancel()
						},
						label: {
							Image(systemName: "xmark.circle.fill")
								.foregroundColor(Color(.lightGray))
								.font(.system(size: 20))
						}
					)
					.padding([.top, .trailing], 24)
				}
			}
			.frame(maxWidth: .infinity, alignment: .bottom)
			.background(
				GeometryReader { proxy in
					ContainerRelativeShape()
						.fill(.background.secondary)
						.preference(
							key: ViewHeightKey.self,
							value: proxy.frame(in: .local).size.height
						)
				}
			)
			.onPreferenceChange(ViewHeightKey.self) {
				panelHeight = $0
			}
			.offset(
				x: 0,
				y: isPresented ? proxy.size.height - panelHeight + offset.height : proxy.size.height
			)
			// Note:
			// Speed of the "move" transition doesn't appear to change
			// when set. Unsure if bug or on purpose.
			// Hence we animate ourselves.
			.animation(
				.spring(response: panelSpringResponse, dampingFraction: 0.9),
				value: isPresented
			)
			.gesture(
				DragGesture()
					.onChanged { gesture in
						offset = gesture.translation
					}
					.onEnded { _ in
						withAnimation {
							if offset.height < 0 {
								offset = .zero
							} else if abs(offset.height) > 100 {
								item = nil
								offset = .zero
							} else {
								offset = .zero
							}
						}
					}
			)
		}
	}
}

// MARK: ViewHeightKey

fileprivate struct ViewHeightKey: PreferenceKey {
	typealias Value = Double
	static var defaultValue = 0.0

	static func reduce(value: inout Value, nextValue: () -> Value) {
		value += nextValue()
	}
}


public extension View {
	/// Presents a panel using the given item as a data source for the panel's content.
	/// - Parameters:
	///   - item: A binding to an optional source of truth for the panel. When the item is non-nil
	///   the panel is presented and populated with the content provided by the `content` parameter.
	///   - onCancel: A closure called when the panel is cancelled. When this is not nil a cancel
	///   button will be added to the panel.
	///   - content: A closure returning the content of the panel.
	func panel<Item: Identifiable, Content: View>(
		item: Binding<Item?>,
		onCancel: (() -> Void)? = nil,
		@ViewBuilder content: @escaping (_ item: Item) -> Content
	) -> some View where Item: Equatable {
		self.modifier(
			Panel(
				item: item,
				onCancel: onCancel,
				contentBuilder: content
			)
		)
	}
}

// Thanks to https://www.avanderlee.com/swiftui/withanimation-completion-callback/
struct AnimationCompletionObserverModifier<Value>: AnimatableModifier where Value: VectorArithmetic {
	var animatableData: Value {
		didSet {
			self.callCompletionIfFinished()
		}
	}

	// Private
	private var targetValue: Value
	private var onComplete: () -> Void

	// MARK: Initialization

	init(observedValue: Value, onComplete: @escaping () -> Void) {
		self.onComplete = onComplete
		self.animatableData = observedValue
		self.targetValue = observedValue
	}

	// MARK: Body

	func body(content: Content) -> some View { content }

	// MARK: Helpers

	private func callCompletionIfFinished() {
		guard self.animatableData == self.targetValue else { return }

		Task {
			self.onComplete()
		}
	}
}

// MARK: View

extension View {
	func onAnimationCompletion<Value: VectorArithmetic>(
		with value: Value,
		onComplete: @escaping () -> Void
	) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
		self.modifier(
			AnimationCompletionObserverModifier(
				observedValue: value,
				onComplete: onComplete
			)
		)
	}
}
