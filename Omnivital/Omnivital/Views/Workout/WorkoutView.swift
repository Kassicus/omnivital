//
//  WorkoutView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct WorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: WorkoutViewModel?

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    if viewModel.activeWorkout != nil {
                        ActiveWorkoutView(viewModel: viewModel)
                    } else {
                        WorkoutHomeView(viewModel: viewModel)
                    }
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle(viewModel?.activeWorkout != nil ? "Workout" : "Lifting")
            .onAppear {
                if viewModel == nil {
                    viewModel = WorkoutViewModel(modelContext: modelContext)
                    viewModel?.loadData()
                }
            }
        }
    }
}

#Preview {
    WorkoutView()
        .modelContainer(for: [Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self], inMemory: true)
}
