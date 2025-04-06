import Combine
//
//  AutoRefreshingView.swift
//  Magnesium
//
//  Created by ninji on 03/04/2025.
//
import SwiftUI

struct AutoRefreshingView<Content: View>: View {
	var refresh: () -> Void
	var content: () -> Content

	@State private var refreshInterval: TimeInterval = Current.preferences[.autoRefreshInterval]
	@State var cancellables: Set<AnyCancellable> = []

	private var timer: Publishers.Autoconnect<Timer.TimerPublisher> {
		Timer.publish(
			every: refreshInterval,
			on: .main,
			in: .common
		)
		.autoconnect()
	}

	var body: some View {
		content()
			.onReceive(timer) { _ in
				if refreshInterval != 0.0 {
					refresh()
				}
			}
			.onAppear {
				Current.preferences
					.changePublisher
					.sink { change in
						switch change {
						case let .updated(key, _):
							if key.identifier == PreferenceKey<TimeInterval>.autoRefreshInterval.identifier {
								refreshInterval = Current.preferences[.autoRefreshInterval]
							}
						default:
							break
						}
					}
					.store(in: &cancellables)
			}
	}
}
