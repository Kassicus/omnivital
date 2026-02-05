//
//  CustomWorkoutTemplate.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class CustomWorkoutTemplate: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorRaw: String
    var exerciseConfigs: [ExerciseConfig]
    var isArchived: Bool
    var createdAt: Date

    @Transient
    var color: WorkoutTemplate.TemplateColor {
        get { WorkoutTemplate.TemplateColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        color: WorkoutTemplate.TemplateColor = .blue,
        exerciseConfigs: [ExerciseConfig] = [],
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.colorRaw = color.rawValue
        self.exerciseConfigs = exerciseConfigs
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}

/// Configuration for an exercise within a workout template
struct ExerciseConfig: Codable, Hashable, Identifiable {
    var id: UUID
    var exerciseId: String  // Either built-in ID or CustomExercise UUID string
    var isCustom: Bool
    var sets: Int
    var reps: Int
    var order: Int

    init(
        id: UUID = UUID(),
        exerciseId: String,
        isCustom: Bool = false,
        sets: Int = 5,
        reps: Int = 5,
        order: Int = 0
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.isCustom = isCustom
        self.sets = sets
        self.reps = reps
        self.order = order
    }
}
