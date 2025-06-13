//
//  OnboardingRouter.swift
//  Magnesium
//
//  Created by ninji on 13/06/2025.
//
import Observation

@Observable
final class OnboardingRouter: RouterProtocol {
	typealias Destination = OnboardingDestinations
	typealias Sheet = OnboardingSheets

	var path: [OnboardingDestinations] = []
	var presentedSheet: OnboardingSheets? = nil
	let parent: (any RouterProtocol)?

	required init(_ parent: (any RouterProtocol)? = nil) {
		self.parent = parent
	}
}
