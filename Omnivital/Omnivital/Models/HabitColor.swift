//
//  HabitColor.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

enum HabitColor: String, Codable, CaseIterable, Sendable, Identifiable {
    case red, orange, yellow, green, mint, teal, cyan, blue, indigo, purple, pink

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .mint: return .mint
        case .teal: return .teal
        case .cyan: return .cyan
        case .blue: return .blue
        case .indigo: return .indigo
        case .purple: return .purple
        case .pink: return .pink
        }
    }

    var displayName: String {
        rawValue.capitalized
    }
}
