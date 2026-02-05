//
//  WorkoutTemplate.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftUI

struct WorkoutTemplate: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let exerciseIds: [String]
    let color: TemplateColor

    var exercises: [ExerciseDefinition] {
        exerciseIds.compactMap { ExerciseDefinition.exercise(byId: $0) }
    }

    enum TemplateColor: String, Codable, Sendable {
        case blue, orange, green, purple, red

        var color: Color {
            switch self {
            case .blue: return .blue
            case .orange: return .orange
            case .green: return .green
            case .purple: return .purple
            case .red: return .red
            }
        }
    }

    // StrongLifts 5x5 Workout A: Squat, Bench Press, Barbell Row
    static let workoutA = WorkoutTemplate(
        id: "stronglifts_a",
        name: "Workout A",
        exerciseIds: ["squat", "bench_press", "barbell_row"],
        color: .blue
    )

    // StrongLifts 5x5 Workout B: Squat, Overhead Press, Deadlift
    static let workoutB = WorkoutTemplate(
        id: "stronglifts_b",
        name: "Workout B",
        exerciseIds: ["squat", "overhead_press", "deadlift"],
        color: .orange
    )

    static let defaultTemplates: [WorkoutTemplate] = [.workoutA, .workoutB]

    static func template(byId id: String) -> WorkoutTemplate? {
        defaultTemplates.first { $0.id == id }
    }
}
