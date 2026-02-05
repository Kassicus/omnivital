//
//  FastingPhase.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

enum FastingPhase: CaseIterable, Identifiable {
    var id: Self { self }
    case fed
    case earlyFasting
    case fastingState
    case fatBurning
    case ketosis
    case deepKetosis

    /// The minimum hours required to enter this phase
    var startHour: Double {
        switch self {
        case .fed: return 0
        case .earlyFasting: return 4
        case .fastingState: return 8
        case .fatBurning: return 12
        case .ketosis: return 18
        case .deepKetosis: return 24
        }
    }

    var displayName: String {
        switch self {
        case .fed: return "Fed State"
        case .earlyFasting: return "Early Fasting"
        case .fastingState: return "Fasting State"
        case .fatBurning: return "Fat Burning"
        case .ketosis: return "Ketosis"
        case .deepKetosis: return "Deep Ketosis"
        }
    }

    var icon: String {
        switch self {
        case .fed: return "fork.knife"
        case .earlyFasting: return "hourglass.bottomhalf.filled"
        case .fastingState: return "flame"
        case .fatBurning: return "flame.fill"
        case .ketosis: return "bolt.fill"
        case .deepKetosis: return "sparkles"
        }
    }

    var color: Color {
        switch self {
        case .fed: return .gray
        case .earlyFasting: return .blue
        case .fastingState: return .cyan
        case .fatBurning: return .orange
        case .ketosis: return .purple
        case .deepKetosis: return .pink
        }
    }

    var shortDescription: String {
        switch self {
        case .fed:
            return "Your body is digesting your last meal"
        case .earlyFasting:
            return "Insulin levels dropping, blood sugar stabilizing"
        case .fastingState:
            return "Glycogen stores depleting, fat burning begins"
        case .fatBurning:
            return "Entering ketosis, autophagy starting"
        case .ketosis:
            return "Full ketosis, significant autophagy"
        case .deepKetosis:
            return "Maximum autophagy, HGH boost"
        }
    }

    var detailedDescription: String {
        switch self {
        case .fed:
            return "Your body is still processing nutrients from your last meal. Blood sugar and insulin levels are elevated as your cells absorb glucose for energy."
        case .earlyFasting:
            return "Insulin levels are dropping and your body is transitioning away from using glucose as its primary fuel source. Blood sugar is stabilizing."
        case .fastingState:
            return "Your body is depleting its glycogen (stored glucose) reserves. As these deplete, your body begins to shift toward burning fat for fuel."
        case .fatBurning:
            return "You're entering ketosis as your liver converts fat stores into ketone bodies. Autophagy—your body's cellular cleanup process—is beginning to ramp up."
        case .ketosis:
            return "You're in full ketosis. Ketones are now powering your muscles, heart, and brain. Autophagy is significantly active, removing damaged cell components."
        case .deepKetosis:
            return "Maximum metabolic adaptation. Growth hormone may increase 300-500%. Autophagy is at peak levels, promoting deep cellular repair and renewal."
        }
    }

    var benefits: [String] {
        switch self {
        case .fed:
            return ["Nutrient absorption", "Energy from food"]
        case .earlyFasting:
            return ["Insulin sensitivity improving", "Blood sugar regulation"]
        case .fastingState:
            return ["Fat mobilization starting", "Mental clarity improving"]
        case .fatBurning:
            return ["Ketone production", "Autophagy activation", "Increased fat burning"]
        case .ketosis:
            return ["Full fat adaptation", "Cellular cleanup", "Reduced inflammation"]
        case .deepKetosis:
            return ["Peak autophagy", "HGH increase", "Enhanced cellular repair", "Immune cell renewal"]
        }
    }

    /// Get the current fasting phase based on elapsed hours
    static func phase(forElapsedHours hours: Double) -> FastingPhase {
        // Iterate in reverse to find the highest phase we've reached
        for phase in FastingPhase.allCases.reversed() {
            if hours >= phase.startHour {
                return phase
            }
        }
        return .fed
    }

    /// Get all phases with their unlock status for a given elapsed time
    static func allPhasesWithStatus(forElapsedHours hours: Double) -> [(phase: FastingPhase, isUnlocked: Bool, isActive: Bool)] {
        let currentPhase = phase(forElapsedHours: hours)
        return FastingPhase.allCases.map { phase in
            (
                phase: phase,
                isUnlocked: hours >= phase.startHour,
                isActive: phase == currentPhase
            )
        }
    }
}
