//
//  HealthMetricType.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

enum HealthMetricType: String, CaseIterable, Identifiable {
    case steps
    case activeCalories
    case heartRate
    case restingHeartRate
    case walkingHeartRateAverage
    case distance
    case sleep
    case standHours

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeCalories: return "Active Calories"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting HR"
        case .walkingHeartRateAverage: return "Walking HR Avg"
        case .distance: return "Distance"
        case .sleep: return "Sleep"
        case .standHours: return "Stand Hours"
        }
    }

    var icon: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeCalories: return "flame.fill"
        case .heartRate: return "heart.fill"
        case .restingHeartRate: return "heart.circle"
        case .walkingHeartRateAverage: return "figure.walk.circle"
        case .distance: return "map"
        case .sleep: return "bed.double.fill"
        case .standHours: return "figure.stand"
        }
    }

    var color: Color {
        switch self {
        case .steps: return .green
        case .activeCalories: return .red
        case .heartRate: return .pink
        case .restingHeartRate: return .purple
        case .walkingHeartRateAverage: return .orange
        case .distance: return .blue
        case .sleep: return .indigo
        case .standHours: return .cyan
        }
    }

    var unit: String {
        switch self {
        case .steps: return "steps"
        case .activeCalories: return "kcal"
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage: return "BPM"
        case .distance: return "mi"
        case .sleep: return "hrs"
        case .standHours: return "hrs"
        }
    }

    var dailyGoal: Double? {
        switch self {
        case .steps: return 10000
        case .activeCalories: return 500
        case .standHours: return 12
        case .sleep: return 8
        default: return nil
        }
    }
}
