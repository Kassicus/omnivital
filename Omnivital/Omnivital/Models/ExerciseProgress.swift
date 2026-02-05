//
//  ExerciseProgress.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class ExerciseProgress: Identifiable {
    @Attribute(.unique) var id: UUID
    var exerciseId: String
    var currentWeightLbs: Double
    var consecutiveFailures: Int
    var lastCompletedDate: Date?
    var personalRecordLbs: Double

    @Transient
    var exercise: ExerciseDefinition? {
        ExerciseDefinition.exercise(byId: exerciseId)
    }

    @Transient
    var needsDeload: Bool {
        consecutiveFailures >= 3
    }

    @Transient
    var deloadWeight: Double {
        // Deload by 10% (rounded to nearest 5)
        let deloaded = currentWeightLbs * 0.9
        return (deloaded / 5).rounded() * 5
    }

    init(
        id: UUID = UUID(),
        exerciseId: String,
        currentWeightLbs: Double,
        consecutiveFailures: Int = 0,
        lastCompletedDate: Date? = nil,
        personalRecordLbs: Double = 0
    ) {
        self.id = id
        self.exerciseId = exerciseId
        self.currentWeightLbs = currentWeightLbs
        self.consecutiveFailures = consecutiveFailures
        self.lastCompletedDate = lastCompletedDate
        self.personalRecordLbs = max(personalRecordLbs, currentWeightLbs)
    }

    /// Called when all sets are completed successfully
    func recordSuccess() {
        guard let exercise = exercise else { return }

        consecutiveFailures = 0
        lastCompletedDate = Date()

        // Increment weight for next session
        currentWeightLbs += exercise.weightIncrementLbs

        // Update PR if needed
        if currentWeightLbs > personalRecordLbs {
            personalRecordLbs = currentWeightLbs
        }
    }

    /// Called when user fails to complete all sets
    func recordFailure() {
        consecutiveFailures += 1
        lastCompletedDate = Date()

        // Auto-deload after 3 consecutive failures
        if needsDeload {
            currentWeightLbs = deloadWeight
            consecutiveFailures = 0
        }
    }

    /// Manual deload
    func performDeload() {
        currentWeightLbs = deloadWeight
        consecutiveFailures = 0
    }

    // Default starting weights for beginners
    static func defaultWeight(for exerciseId: String) -> Double {
        switch exerciseId {
        case "squat": return 45
        case "bench_press": return 45
        case "barbell_row": return 65
        case "overhead_press": return 45
        case "deadlift": return 95
        default: return 45
        }
    }
}
