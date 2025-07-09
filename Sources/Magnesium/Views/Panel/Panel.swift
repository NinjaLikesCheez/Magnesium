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

	private var panelSpringResponse: Double {
		self.isPresented ? 0.25 : 0.15
	}

	private var backgroundAnimationDuration: Double {
		self.isPresented ? 0.25 : 0.15
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
				self.background()
				self.panelContent()
			}
			.padding([.leading, .trailing], 15)
			.frame(maxWidth: .infinity, maxHeight: .infinity)
			.ignoresSafeArea()
			.onChange(of: self.item) { _, newValue in
				if let item = newValue {
					// If currently presented, we need to dismiss first
					if self.isPresented {
						self.closePanel()
					} else {
						self.presentPanel(for: item)
					}
				} else {
					self.closePanel()
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
			if self.isPresented {
				Color.black.opacity(0.8)
					.ignoresSafeArea()
					.transition(
						.opacity.animation(
							.easeInOut(duration: self.backgroundAnimationDuration)
						)
					)
			}
		}
	}

	private func panelContent() -> some View {
		GeometryReader { proxy in
			ZStack(alignment: .topTrailing) {
				self.content
					.padding(EdgeInsets(top: 32.0, leading: 24.0, bottom: 32.0, trailing: 24.0))

				if let onCancel = self.onCancel {
					Button(
						action: {
							self.item = nil
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
					RoundedRectangle(cornerRadius: 40, style: .continuous)
						.fill(Color.white)
						.preference(
							key: ViewHeightKey.self,
							value: proxy.frame(in: .local).size.height
						)
				}
			)
			.onPreferenceChange(ViewHeightKey.self) {
				self.panelHeight = $0
			}
			.offset(
				x: 0,
				y: self.isPresented ? proxy.size.height - self.panelHeight : proxy.size.height
			)
			// Note:
			// Speed of the "move" transition doesn't appear to change
			// when set. Unsure if bug or on purpose.
			// Hence we animate ourselves.
			.animation(
				.spring(response: self.panelSpringResponse, dampingFraction: 0.9),
				value: self.isPresented
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

// MARK: Previews

struct PanelSheet_Previews: PreviewProvider {
	static var previews: some View {
		VStack {
			Text("Hello")
		}
		.modifier(
			Panel(
				item: .constant(PanelItem.wifi),
				onCancel: {},
				contentBuilder: { _ in
					VStack(spacing: 24) {
						VStack(spacing: 32) {
							Text("Wi-Fi Password")
								.font(.title)
								.foregroundColor(Color(.darkGray))

							Image(systemName: "wifi")
								.font(.system(size: 100))
								.foregroundColor(Color(.lightGray))

							Text("Do you want to share the Wi-Fi password for \"Home\" with Pita Bread?")
								.multilineTextAlignment(.center)
						}

						Button(
							action: {},
							label: {
								Text("Done")
									.frame(maxWidth: .infinity)
							}
						)
						.buttonStyle(.borderedProminent)
						.controlSize(.large)
					}
				}
			)
		)
	}

	fileprivate enum PanelItem: String, Identifiable {
		case wifi
		var id: String { self.rawValue }
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
