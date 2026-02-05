//
//  Exercise.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation

enum MuscleGroup: String, Codable, CaseIterable, Sendable {
    case chest
    case back
    case shoulders
    case legs
    case arms
    case core
    case fullBody

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .legs: return "Legs"
        case .arms: return "Arms"
        case .core: return "Core"
        case .fullBody: return "Full Body"
        }
    }

    var icon: String {
        switch self {
        case .chest: return "figure.strengthtraining.traditional"
        case .back: return "figure.rowing"
        case .shoulders: return "figure.arms.open"
        case .legs: return "figure.run"
        case .arms: return "figure.boxing"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.mixed.cardio"
        }
    }
}

struct ExerciseDefinition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let muscleGroup: MuscleGroup
    let defaultSets: Int
    let defaultReps: Int
    let weightIncrementLbs: Double
    let isCompound: Bool

    static let squat = ExerciseDefinition(
        id: "squat",
        name: "Squat",
        muscleGroup: .legs,
        defaultSets: 5,
        defaultReps: 5,
        weightIncrementLbs: 5,
        isCompound: true
    )

    static let benchPress = ExerciseDefinition(
        id: "bench_press",
        name: "Bench Press",
        muscleGroup: .chest,
        defaultSets: 5,
        defaultReps: 5,
        weightIncrementLbs: 5,
        isCompound: true
    )

    static let barbellRow = ExerciseDefinition(
        id: "barbell_row",
        name: "Barbell Row",
        muscleGroup: .back,
        defaultSets: 5,
        defaultReps: 5,
        weightIncrementLbs: 5,
        isCompound: true
    )

    static let overheadPress = ExerciseDefinition(
        id: "overhead_press",
        name: "Overhead Press",
        muscleGroup: .shoulders,
        defaultSets: 5,
        defaultReps: 5,
        weightIncrementLbs: 5,
        isCompound: true
    )

    static let deadlift = ExerciseDefinition(
        id: "deadlift",
        name: "Deadlift",
        muscleGroup: .back,
        defaultSets: 1,
        defaultReps: 5,
        weightIncrementLbs: 5,
        isCompound: true
    )

    static let allExercises: [ExerciseDefinition] = [
        .squat, .benchPress, .barbellRow, .overheadPress, .deadlift
    ]

    static func exercise(byId id: String) -> ExerciseDefinition? {
        allExercises.first { $0.id == id }
    }
}
