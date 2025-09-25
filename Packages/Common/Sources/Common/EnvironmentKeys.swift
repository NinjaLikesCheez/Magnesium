//
//  EnvironmentKeys.swift
//  Magnesium
//
//  Created by ninji on 25/06/2025.
//
import SwiftUI

public enum Idiom: Sendable{
	case unspecified
	case phone
	case pad
	case tv
	case carPlay
	case macCatalyst
	case vision
	case mac

	#if !os(macOS)
	public init(_ idiom: UIUserInterfaceIdiom) {
		self = switch idiom {
		case .unspecified: .unspecified
		case .phone: .phone
		case .pad: .pad
		case .tv: .tv
		case .carPlay: .carPlay
		case .mac: .macCatalyst
		case .vision: .vision
		@unknown default:
			fatalError("Unknown user interface idiom")
		}
	}
	#endif
}

@MainActor
private struct UserInterfaceIdiomEnvironmentKey: @MainActor EnvironmentKey {
	#if !os(macOS)
	static let defaultValue: Idiom = .init(UIDevice.current.userInterfaceIdiom)
	#elseif os(macOS)
	static let defaultValue: Idiom = .mac
	#else
	static let defaultValue: Idiom = .unspecified
	#endif
}

@MainActor
public extension EnvironmentValues {
	var userInterfaceIdiom: Idiom {
		get { self[UserInterfaceIdiomEnvironmentKey.self] }
		set { self[UserInterfaceIdiomEnvironmentKey.self] = newValue }
	}
}
