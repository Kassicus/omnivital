//
//  MainTabView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    let healthKitManager: HealthKitManager

    var body: some View {
        TabView {
            HealthDashboardView(healthKitManager: healthKitManager)
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }

            FastingView()
                .tabItem {
                    Label("Fasting", systemImage: "fork.knife.circle")
                }

            WorkoutView()
                .tabItem {
                    Label("Lifting", systemImage: "dumbbell.fill")
                }
        }
    }
}

#Preview {
    MainTabView(healthKitManager: HealthKitManager())
        .modelContainer(for: [Fast.self, Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self], inMemory: true)
}
