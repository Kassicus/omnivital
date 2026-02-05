//
//  CustomExercise.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class CustomExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var muscleGroupRaw: String
    var defaultSets: Int
    var defaultReps: Int
    var weightIncrementLbs: Double
    var isCompound: Bool
    var isArchived: Bool
    var createdAt: Date

    @Transient
    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    /// Convert to ExerciseDefinition for use in workouts
    @Transient
    var asDefinition: ExerciseDefinition {
        ExerciseDefinition(
            id: id.uuidString,
            name: name,
            muscleGroup: muscleGroup,
            defaultSets: defaultSets,
            defaultReps: defaultReps,
            weightIncrementLbs: weightIncrementLbs,
            isCompound: isCompound
        )
    }

    init(
        id: UUID = UUID(),
        name: String,
        muscleGroup: MuscleGroup = .fullBody,
        defaultSets: Int = 3,
        defaultReps: Int = 10,
        weightIncrementLbs: Double = 5,
        isCompound: Bool = true,
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.muscleGroupRaw = muscleGroup.rawValue
        self.defaultSets = defaultSets
        self.defaultReps = defaultReps
        self.weightIncrementLbs = weightIncrementLbs
        self.isCompound = isCompound
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
