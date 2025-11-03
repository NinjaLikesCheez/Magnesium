//
//  AppError.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//

import Router
import SwiftUI

enum AppError: RoutableError {
	var id: Self { fatalError("Not yet implemented") }
}

struct AppErrorModifier: RoutableErrorViewModifier {
	@Binding var router: AppRouter

	func body(content: Content) -> some View {
		content
			.panel(item: $router.presentedError) { error in
				switch error {
				default: fatalError("Not yet implemented")
				}
			}
	}
}

extension View {
	func withAppErrors(router: Binding<AppRouter>) -> some View {
		modifier(AppErrorModifier(router: router))
	}
}
