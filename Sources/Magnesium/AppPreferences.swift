//
//  AppPreferences.swift
//  Magnesium
//
//  Created by ninji on 03/11/2025.
//
import Foundation
import ObservableDefaults

@ObservableDefaults
@MainActor
final class AppPreferences {
	var onboarded: Bool = false
}
