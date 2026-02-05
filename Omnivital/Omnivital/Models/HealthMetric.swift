//
//  HealthMetric.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation

struct HealthMetric: Identifiable {
    let id = UUID()
    let type: HealthMetricType
    let value: Double
    let date: Date

    var formattedValue: String {
        switch type {
        case .steps:
            return String(format: "%.0f", value)
        case .activeCalories:
            return String(format: "%.0f", value)
        case .heartRate, .restingHeartRate, .walkingHeartRateAverage:
            return String(format: "%.0f", value)
        case .distance:
            return String(format: "%.2f", value)
        case .sleep:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .standHours:
            return String(format: "%.0f", value)
        }
    }

    var progress: Double? {
        guard let goal = type.dailyGoal, goal > 0 else { return nil }
        return min(value / goal, 1.0)
    }
}
