//
//  AppRouter.swift
//  Magnesium
//
//  Created by ninji on 12/06/2025.
//
import Observation

@Observable
final class AppRouter: RouterProtocol {
	typealias Destination = AppDestination
	typealias Sheet = AppSheet
	
	var path: [AppDestination] = []
	var presentedSheet: AppSheet? = nil
	let parent: (any RouterProtocol)?
	
	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
