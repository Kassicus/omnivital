//
//  WorkoutViewModel.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class WorkoutViewModel {
    private let modelContext: ModelContext

    var activeWorkout: Workout?
    var recentWorkouts: [Workout] = []
    var exerciseProgress: [String: ExerciseProgress] = [:]

    // Custom content
    var customExercises: [CustomExercise] = []
    var customTemplates: [CustomWorkoutTemplate] = []

    var currentExerciseIndex: Int = 0
    var currentSetIndex: Int = 0
    var isResting: Bool = false
    var restTimeRemaining: Int = 180 // 3 minutes in seconds

    var isLoading: Bool = false
    var error: Error?

    // Timer
    private var restTimer: Timer?

    var currentExercise: WorkoutExercise? {
        guard let workout = activeWorkout,
              currentExerciseIndex < workout.exercises.count else { return nil }
        return workout.exercises.sorted { $0.order < $1.order }[currentExerciseIndex]
    }

    var currentSet: WorkoutSet? {
        guard let exercise = currentExercise,
              currentSetIndex < exercise.sets.count else { return nil }
        return exercise.sets.sorted { $0.setNumber < $1.setNumber }[currentSetIndex]
    }

    /// All available exercises (built-in + custom)
    var allExercises: [ExerciseDefinition] {
        let builtIn = ExerciseDefinition.allExercises
        let custom = customExercises.filter { !$0.isArchived }.map { $0.asDefinition }
        return builtIn + custom
    }

    /// All available templates (built-in + custom)
    var allTemplates: [WorkoutTemplateWrapper] {
        let builtIn = WorkoutTemplate.defaultTemplates.map { WorkoutTemplateWrapper.builtIn($0) }
        let custom = customTemplates.filter { !$0.isArchived }.map { WorkoutTemplateWrapper.custom($0) }
        return builtIn + custom
    }

    var nextWorkoutTemplate: WorkoutTemplateWrapper {
        // Alternate between A and B based on last workout (only for built-in)
        if let lastWorkout = recentWorkouts.first {
            if lastWorkout.templateId == WorkoutTemplate.workoutA.id {
                return .builtIn(WorkoutTemplate.workoutB)
            } else if lastWorkout.templateId == WorkoutTemplate.workoutB.id {
                return .builtIn(WorkoutTemplate.workoutA)
            }
        }
        return .builtIn(WorkoutTemplate.workoutA)
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadData() {
        isLoading = true
        error = nil

        do {
            // Load active workout
            let activeDescriptor = FetchDescriptor<Workout>(
                predicate: #Predicate { $0.endTime == nil },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            let activeWorkouts = try modelContext.fetch(activeDescriptor)
            self.activeWorkout = activeWorkouts.first

            // Resume workout state if active
            if let workout = activeWorkout {
                resumeWorkoutState(workout)
            }

            // Load recent workouts (completed)
            let recentDescriptor = FetchDescriptor<Workout>(
                predicate: #Predicate { $0.endTime != nil },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            self.recentWorkouts = try modelContext.fetch(recentDescriptor)

            // Load custom exercises
            let exerciseDescriptor = FetchDescriptor<CustomExercise>(
                sortBy: [SortDescriptor(\.name)]
            )
            self.customExercises = try modelContext.fetch(exerciseDescriptor)

            // Load custom templates
            let templateDescriptor = FetchDescriptor<CustomWorkoutTemplate>(
                sortBy: [SortDescriptor(\.name)]
            )
            self.customTemplates = try modelContext.fetch(templateDescriptor)

            // Load exercise progress
            let progressDescriptor = FetchDescriptor<ExerciseProgress>()
            let progressList = try modelContext.fetch(progressDescriptor)
            self.exerciseProgress = Dictionary(uniqueKeysWithValues: progressList.map { ($0.exerciseId, $0) })

            // Initialize missing progress for built-in exercises
            for exercise in ExerciseDefinition.allExercises {
                if exerciseProgress[exercise.id] == nil {
                    let progress = ExerciseProgress(
                        exerciseId: exercise.id,
                        currentWeightLbs: ExerciseProgress.defaultWeight(for: exercise.id)
                    )
                    modelContext.insert(progress)
                    exerciseProgress[exercise.id] = progress
                }
            }

            // Initialize progress for custom exercises
            for exercise in customExercises where !exercise.isArchived {
                let exerciseId = exercise.id.uuidString
                if exerciseProgress[exerciseId] == nil {
                    let progress = ExerciseProgress(
                        exerciseId: exerciseId,
                        currentWeightLbs: 45 // Default starting weight
                    )
                    modelContext.insert(progress)
                    exerciseProgress[exerciseId] = progress
                }
            }

            try modelContext.save()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Exercise Management

    func getExerciseDefinition(byId id: String) -> ExerciseDefinition? {
        // Check built-in first
        if let builtIn = ExerciseDefinition.exercise(byId: id) {
            return builtIn
        }
        // Check custom
        if let uuid = UUID(uuidString: id),
           let custom = customExercises.first(where: { $0.id == uuid }) {
            return custom.asDefinition
        }
        return nil
    }

    func createExercise(
        name: String,
        muscleGroup: MuscleGroup,
        defaultSets: Int,
        defaultReps: Int,
        weightIncrement: Double,
        isCompound: Bool
    ) {
        let exercise = CustomExercise(
            name: name,
            muscleGroup: muscleGroup,
            defaultSets: defaultSets,
            defaultReps: defaultReps,
            weightIncrementLbs: weightIncrement,
            isCompound: isCompound
        )
        modelContext.insert(exercise)

        // Create progress entry
        let progress = ExerciseProgress(
            exerciseId: exercise.id.uuidString,
            currentWeightLbs: 45
        )
        modelContext.insert(progress)

        do {
            try modelContext.save()
            customExercises.append(exercise)
            exerciseProgress[exercise.id.uuidString] = progress
        } catch {
            self.error = error
        }
    }

    func updateExercise(_ exercise: CustomExercise) {
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    func archiveExercise(_ exercise: CustomExercise) {
        exercise.isArchived = true
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    func updateExerciseProgress(_ exerciseId: String, weight: Double) {
        if let progress = exerciseProgress[exerciseId] {
            progress.currentWeightLbs = weight
            do {
                try modelContext.save()
            } catch {
                self.error = error
            }
        }
    }

    // MARK: - Template Management

    func createTemplate(
        name: String,
        color: WorkoutTemplate.TemplateColor,
        exercises: [ExerciseConfig]
    ) {
        let template = CustomWorkoutTemplate(
            name: name,
            color: color,
            exerciseConfigs: exercises
        )
        modelContext.insert(template)

        do {
            try modelContext.save()
            customTemplates.append(template)
        } catch {
            self.error = error
        }
    }

    func updateTemplate(_ template: CustomWorkoutTemplate) {
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    func archiveTemplate(_ template: CustomWorkoutTemplate) {
        template.isArchived = true
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    // MARK: - Workout Management

    private func resumeWorkoutState(_ workout: Workout) {
        let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

        // Find first incomplete exercise
        for (index, exercise) in sortedExercises.enumerated() {
            let sortedSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }
            if let setIndex = sortedSets.firstIndex(where: { !$0.completed && !$0.failed }) {
                currentExerciseIndex = index
                currentSetIndex = setIndex
                return
            }
        }

        // All complete, set to last
        currentExerciseIndex = max(0, sortedExercises.count - 1)
        currentSetIndex = 0
    }

    func startWorkout(template: WorkoutTemplateWrapper) {
        switch template {
        case .builtIn(let builtInTemplate):
            startBuiltInWorkout(template: builtInTemplate)
        case .custom(let customTemplate):
            startCustomWorkout(template: customTemplate)
        }
    }

    private func startBuiltInWorkout(template: WorkoutTemplate) {
        let workout = Workout(templateId: template.id)
        modelContext.insert(workout)

        // Create exercises with sets
        for (index, exerciseDef) in template.exercises.enumerated() {
            let workoutExercise = WorkoutExercise(
                exerciseId: exerciseDef.id,
                order: index
            )
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)

            // Get current weight for this exercise
            let weight = exerciseProgress[exerciseDef.id]?.currentWeightLbs
                ?? ExerciseProgress.defaultWeight(for: exerciseDef.id)

            // Create sets
            for setNum in 1...exerciseDef.defaultSets {
                let set = WorkoutSet(
                    setNumber: setNum,
                    targetReps: exerciseDef.defaultReps,
                    weight: weight
                )
                set.workoutExercise = workoutExercise
                workoutExercise.sets.append(set)
            }
        }

        do {
            try modelContext.save()
            activeWorkout = workout
            currentExerciseIndex = 0
            currentSetIndex = 0
        } catch {
            self.error = error
        }
    }

    private func startCustomWorkout(template: CustomWorkoutTemplate) {
        let workout = Workout(templateId: template.id.uuidString)
        modelContext.insert(workout)

        // Create exercises with sets from config
        for config in template.exerciseConfigs.sorted(by: { $0.order < $1.order }) {
            let workoutExercise = WorkoutExercise(
                exerciseId: config.exerciseId,
                order: config.order
            )
            workoutExercise.workout = workout
            workout.exercises.append(workoutExercise)

            // Get current weight for this exercise
            let weight = exerciseProgress[config.exerciseId]?.currentWeightLbs ?? 45

            // Create sets
            for setNum in 1...config.sets {
                let set = WorkoutSet(
                    setNumber: setNum,
                    targetReps: config.reps,
                    weight: weight
                )
                set.workoutExercise = workoutExercise
                workoutExercise.sets.append(set)
            }
        }

        do {
            try modelContext.save()
            activeWorkout = workout
            currentExerciseIndex = 0
            currentSetIndex = 0
        } catch {
            self.error = error
        }
    }

    func completeSet(reps: Int) {
        guard let set = currentSet else { return }

        set.reps = reps
        set.completed = true
        set.failed = reps < set.targetReps
        set.completedAt = Date()

        do {
            try modelContext.save()
        } catch {
            self.error = error
        }

        // Move to next set or exercise
        advanceToNextSet()
    }

    func failSet() {
        guard let set = currentSet else { return }

        set.reps = 0
        set.completed = false
        set.failed = true
        set.completedAt = Date()

        do {
            try modelContext.save()
        } catch {
            self.error = error
        }

        advanceToNextSet()
    }

    private func advanceToNextSet() {
        guard let exercise = currentExercise else { return }

        let sortedSets = exercise.sets.sorted { $0.setNumber < $1.setNumber }

        if currentSetIndex + 1 < sortedSets.count {
            // More sets in this exercise
            currentSetIndex += 1
            startRestTimer()
        } else {
            // Exercise complete, check for next
            guard let workout = activeWorkout else { return }
            let sortedExercises = workout.exercises.sorted { $0.order < $1.order }

            if currentExerciseIndex + 1 < sortedExercises.count {
                // Move to next exercise
                currentExerciseIndex += 1
                currentSetIndex = 0
                startRestTimer()
            } else {
                // Workout complete - handled in UI
                stopRestTimer()
            }
        }
    }

    func startRestTimer() {
        isResting = true
        restTimeRemaining = 180 // 3 minutes

        stopRestTimer() // Clear any existing timer

        restTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                } else {
                    self.stopRestTimer()
                }
            }
        }
    }

    func skipRest() {
        stopRestTimer()
    }

    func addRestTime(_ seconds: Int) {
        restTimeRemaining += seconds
    }

    private func stopRestTimer() {
        restTimer?.invalidate()
        restTimer = nil
        isResting = false
    }

    func finishWorkout() {
        guard let workout = activeWorkout else { return }

        workout.endTime = Date()

        // Update exercise progress based on results
        for workoutExercise in workout.exercises {
            // Get or create progress
            var progress = exerciseProgress[workoutExercise.exerciseId]
            if progress == nil {
                // Create progress for new exercise
                let newProgress = ExerciseProgress(
                    exerciseId: workoutExercise.exerciseId,
                    currentWeightLbs: workoutExercise.sets.first?.weight ?? 45
                )
                modelContext.insert(newProgress)
                progress = newProgress
                exerciseProgress[workoutExercise.exerciseId] = newProgress
            }

            guard let progress = progress else { continue }

            if workoutExercise.allSetsCompleted && workoutExercise.failedSetsCount == 0 {
                progress.recordSuccess()
            } else if workoutExercise.failedSetsCount > 0 {
                progress.recordFailure()
            }
        }

        do {
            try modelContext.save()
            stopRestTimer()
            activeWorkout = nil
            currentExerciseIndex = 0
            currentSetIndex = 0
            loadData() // Reload to update recent workouts
        } catch {
            self.error = error
        }
    }

    func cancelWorkout() {
        guard let workout = activeWorkout else { return }

        modelContext.delete(workout)

        do {
            try modelContext.save()
            stopRestTimer()
            activeWorkout = nil
            currentExerciseIndex = 0
            currentSetIndex = 0
        } catch {
            self.error = error
        }
    }

    func updateSetWeight(_ set: WorkoutSet, weight: Double) {
        set.weight = weight
        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }

    var isWorkoutComplete: Bool {
        guard let workout = activeWorkout else { return false }
        return workout.exercises.allSatisfy { exercise in
            exercise.sets.allSatisfy { $0.completed || $0.failed }
        }
    }
}

// MARK: - Wrapper for built-in and custom templates

enum WorkoutTemplateWrapper: Identifiable {
    case builtIn(WorkoutTemplate)
    case custom(CustomWorkoutTemplate)

    var id: String {
        switch self {
        case .builtIn(let template): return template.id
        case .custom(let template): return template.id.uuidString
        }
    }

    var name: String {
        switch self {
        case .builtIn(let template): return template.name
        case .custom(let template): return template.name
        }
    }

    var color: WorkoutTemplate.TemplateColor {
        switch self {
        case .builtIn(let template): return template.color
        case .custom(let template): return template.color
        }
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
}
