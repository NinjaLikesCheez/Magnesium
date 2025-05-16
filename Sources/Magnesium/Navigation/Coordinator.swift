//
//  Coordinator.swift
//  Magnesium
//
//  Created by ninji on 10/05/2025.
//

import SwiftUI

//public protocol Dependencies {}

protocol Coordinator: View {
	associatedtype Dependencies
	associatedtype Destinations: Hashable
	associatedtype Sheets: Hashable & Identifiable

	var dependencies: Dependencies { get }

	init(dependencies: Dependencies)
}
