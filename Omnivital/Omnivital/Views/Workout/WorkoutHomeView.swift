//
//  WorkoutHomeView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct WorkoutHomeView: View {
    @Bindable var viewModel: WorkoutViewModel
    @State private var showingWorkoutPicker = false
    @State private var showingExerciseList = false
    @State private var showingTemplateList = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Next workout card
                NextWorkoutCard(
                    template: viewModel.nextWorkoutTemplate,
                    exerciseProgress: viewModel.exerciseProgress,
                    viewModel: viewModel,
                    onStart: {
                        viewModel.startWorkout(template: viewModel.nextWorkoutTemplate)
                    },
                    onPickDifferent: {
                        showingWorkoutPicker = true
                    }
                )
                .padding(.horizontal)

                // Quick actions
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Exercises",
                        icon: "dumbbell.fill",
                        color: .blue
                    ) {
                        showingExerciseList = true
                    }

                    QuickActionButton(
                        title: "Workouts",
                        icon: "list.clipboard.fill",
                        color: .orange
                    ) {
                        showingTemplateList = true
                    }
                }
                .padding(.horizontal)

                // Current progress section
                if !viewModel.exerciseProgress.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Your Lifts")
                                .font(.headline)

                            Spacer()

                            Button("See All") {
                                showingExerciseList = true
                            }
                            .font(.subheadline)
                        }
                        .padding(.horizontal)

                        // Show first 5 exercises
                        ForEach(viewModel.allExercises.prefix(5), id: \.id) { exercise in
                            if let progress = viewModel.exerciseProgress[exercise.id] {
                                ExerciseProgressRow(exercise: exercise, progress: progress)
                            }
                        }
                    }
                }

                // Recent workouts
                if !viewModel.recentWorkouts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Workouts")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.recentWorkouts.prefix(5)) { workout in
                            WorkoutHistoryRow(workout: workout, viewModel: viewModel)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .sheet(isPresented: $showingWorkoutPicker) {
            WorkoutPickerSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingExerciseList) {
            ExerciseListView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingTemplateList) {
            TemplateListView(viewModel: viewModel)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.bordered)
    }
}

struct NextWorkoutCard: View {
    let template: WorkoutTemplateWrapper
    let exerciseProgress: [String: ExerciseProgress]
    let viewModel: WorkoutViewModel
    let onStart: () -> Void
    let onPickDifferent: () -> Void

    private var exercises: [(id: String, name: String, sets: Int, reps: Int)] {
        switch template {
        case .builtIn(let t):
            return t.exercises.map { ($0.id, $0.name, $0.defaultSets, $0.defaultReps) }
        case .custom(let t):
            return t.exerciseConfigs.compactMap { config in
                guard let exercise = viewModel.getExerciseDefinition(byId: config.exerciseId) else { return nil }
                return (config.exerciseId, exercise.name, config.sets, config.reps)
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next Workout")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(template.name)
                        .font(.title)
                        .fontWeight(.bold)
                }

                Spacer()

                Circle()
                    .fill(template.color.color)
                    .frame(width: 50, height: 50)
                    .overlay {
                        Text(template.name.prefix(1))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
            }

            Divider()

            // Exercise list with weights
            VStack(spacing: 8) {
                ForEach(exercises, id: \.id) { exercise in
                    HStack {
                        Text(exercise.name)
                            .font(.subheadline)

                        Spacer()

                        if let progress = exerciseProgress[exercise.id] {
                            Text("\(Int(progress.currentWeightLbs)) lbs")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(template.color.color)
                        }

                        Text("\(exercise.sets)×\(exercise.reps)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                Button(action: onPickDifferent) {
                    Text("Change")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button(action: onStart) {
                    Label("Start Workout", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(template.color.color)
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct ExerciseProgressRow: View {
    let exercise: ExerciseDefinition
    let progress: ExerciseProgress

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: exercise.muscleGroup.icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 36)

            Text(exercise.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(Int(progress.currentWeightLbs)) lbs")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if progress.personalRecordLbs > 0 {
                    Text("PR: \(Int(progress.personalRecordLbs))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct WorkoutHistoryRow: View {
    let workout: Workout
    let viewModel: WorkoutViewModel

    private var templateInfo: (name: String, color: WorkoutTemplate.TemplateColor)? {
        // Check built-in templates first
        if let template = workout.template {
            return (template.name, template.color)
        }
        // Check custom templates
        if let uuid = UUID(uuidString: workout.templateId),
           let customTemplate = viewModel.customTemplates.first(where: { $0.id == uuid }) {
            return (customTemplate.name, customTemplate.color)
        }
        return nil
    }

    var body: some View {
        HStack(spacing: 12) {
            if let info = templateInfo {
                Circle()
                    .fill(info.color.color)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Text(info.name.prefix(1))
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
            } else {
                Circle()
                    .fill(Color.gray)
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "dumbbell.fill")
                            .foregroundStyle(.white)
                    }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(templateInfo?.name ?? "Workout")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(workout.startTime, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(workout.durationFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("\(workout.completedSetsCount)/\(workout.totalSetsCount) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

struct WorkoutPickerSheet: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateTemplate = false

    var body: some View {
        NavigationStack {
            List {
                // Built-in templates
                Section("StrongLifts 5×5") {
                    ForEach(WorkoutTemplate.defaultTemplates, id: \.id) { template in
                        Button {
                            viewModel.startWorkout(template: .builtIn(template))
                            dismiss()
                        } label: {
                            TemplatePickerRow(
                                name: template.name,
                                color: template.color,
                                exerciseNames: template.exercises.map { $0.name }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Custom templates
                if !viewModel.customTemplates.filter({ !$0.isArchived }).isEmpty {
                    Section("Custom Workouts") {
                        ForEach(viewModel.customTemplates.filter { !$0.isArchived }) { template in
                            Button {
                                viewModel.startWorkout(template: .custom(template))
                                dismiss()
                            } label: {
                                TemplatePickerRow(
                                    name: template.name,
                                    color: template.color,
                                    exerciseNames: template.exerciseConfigs.compactMap { config in
                                        viewModel.getExerciseDefinition(byId: config.exerciseId)?.name
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Create new
                Section {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Label("Create New Workout", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Choose Workout")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                TemplateEditorView(viewModel: viewModel, template: nil)
            }
        }
    }
}

struct TemplatePickerRow: View {
    let name: String
    let color: WorkoutTemplate.TemplateColor
    let exerciseNames: [String]

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.color)
                .frame(width: 44, height: 44)
                .overlay {
                    Text(name.prefix(1))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(exerciseNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    WorkoutHomeView(viewModel: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self, CustomExercise.self, CustomWorkoutTemplate.self, configurations: config)
        let vm = WorkoutViewModel(modelContext: container.mainContext)
        vm.loadData()
        return vm
    }())
}
