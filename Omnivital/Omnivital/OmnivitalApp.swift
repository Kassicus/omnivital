//
//  OmnivitalApp.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

@main
struct OmnivitalApp: App {
    @State private var healthKitManager = HealthKitManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Fast.self,
            Workout.self,
            WorkoutExercise.self,
            WorkoutSet.self,
            ExerciseProgress.self,
            CustomExercise.self,
            CustomWorkoutTemplate.self,
            Habit.self,
            HabitCompletion.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView(healthKitManager: healthKitManager)
        }
        .modelContainer(sharedModelContainer)
    }
}
