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

	private var refreshInterval: TimeInterval

	init(every interval: TimeInterval, refresh: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
		refreshInterval = interval
		self.refresh = refresh
		self.content = content
	}

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
			.onAppear() { refresh() }
			.onReceive(timer) { _ in
				if refreshInterval != 0.0 {
					refresh()
				}
			}
	}
}
