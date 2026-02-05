//
//  Workout.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class Workout: Identifiable {
    @Attribute(.unique) var id: UUID
    var templateId: String
    var startTime: Date
    var endTime: Date?
    var notes: String?

    @Relationship(deleteRule: .cascade) var exercises: [WorkoutExercise] = []

    @Transient
    var template: WorkoutTemplate? {
        WorkoutTemplate.template(byId: templateId)
    }

    @Transient
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    @Transient
    var durationFormatted: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    @Transient
    var isActive: Bool {
        endTime == nil
    }

    @Transient
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                if set.completed {
                    return setTotal + (set.weight * Double(set.reps))
                }
                return setTotal
            }
        }
    }

    @Transient
    var completedSetsCount: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.completed }.count }
    }

    @Transient
    var totalSetsCount: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    init(
        id: UUID = UUID(),
        templateId: String,
        startTime: Date = Date(),
        endTime: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.startTime = startTime
        self.endTime = endTime
        self.notes = notes
    }
}

@Model
final class WorkoutExercise: Identifiable {
    @Attribute(.unique) var id: UUID
    var exerciseId: String
    var order: Int

    @Relationship(deleteRule: .cascade) var sets: [WorkoutSet] = []
    var workout: Workout?

    @Transient
    var exercise: ExerciseDefinition? {
        ExerciseDefinition.exercise(byId: exerciseId)
    }

    @Transient
    var allSetsCompleted: Bool {
        !sets.isEmpty && sets.allSatisfy { $0.completed }
    }

    @Transient
    var completedSetsCount: Int {
        sets.filter { $0.completed }.count
    }

    @Transient
    var failedSetsCount: Int {
        sets.filter { $0.failed }.count
    }

    init(
        id: UUID = UUID(),
        exerciseId: String,
        order: Int
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.order = order
    }
}

@Model
final class WorkoutSet: Identifiable {
    @Attribute(.unique) var id: UUID
    var setNumber: Int
    var targetReps: Int
    var reps: Int
    var weight: Double
    var completed: Bool
    var failed: Bool
    var completedAt: Date?

    var workoutExercise: WorkoutExercise?

    init(
        id: UUID = UUID(),
        setNumber: Int,
        targetReps: Int,
        reps: Int = 0,
        weight: Double,
        completed: Bool = false,
        failed: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.setNumber = setNumber
        self.targetReps = targetReps
        self.reps = reps
        self.weight = weight
        self.completed = completed
        self.failed = failed
        self.completedAt = completedAt
    }
}
