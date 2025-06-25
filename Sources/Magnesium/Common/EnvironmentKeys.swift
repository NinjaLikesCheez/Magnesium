//
//  EnvironmentKeys.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI

private struct UserInterfaceIdiomEnvironmentKey: EnvironmentKey {
	static let defaultValue: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom
}

extension EnvironmentValues {
	var userInterfaceIdiom: UIUserInterfaceIdiom {
		get { self[UserInterfaceIdiomEnvironmentKey.self] }
		set { self[UserInterfaceIdiomEnvironmentKey.self] = newValue }
	}
}
