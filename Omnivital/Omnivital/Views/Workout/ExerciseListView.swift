//
//  ExerciseListView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct ExerciseListView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateExercise = false
    @State private var exerciseToEdit: CustomExercise?
    @State private var progressToEdit: (exerciseId: String, name: String)?

    var body: some View {
        NavigationStack {
            List {
                // Built-in exercises
                Section("StrongLifts 5×5") {
                    ForEach(ExerciseDefinition.allExercises, id: \.id) { exercise in
                        ExerciseRow(
                            name: exercise.name,
                            muscleGroup: exercise.muscleGroup,
                            sets: exercise.defaultSets,
                            reps: exercise.defaultReps,
                            weight: viewModel.exerciseProgress[exercise.id]?.currentWeightLbs,
                            isBuiltIn: true
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            progressToEdit = (exercise.id, exercise.name)
                        }
                    }
                }

                // Custom exercises
                if !viewModel.customExercises.filter({ !$0.isArchived }).isEmpty {
                    Section("Custom Exercises") {
                        ForEach(viewModel.customExercises.filter { !$0.isArchived }) { exercise in
                            ExerciseRow(
                                name: exercise.name,
                                muscleGroup: exercise.muscleGroup,
                                sets: exercise.defaultSets,
                                reps: exercise.defaultReps,
                                weight: viewModel.exerciseProgress[exercise.id.uuidString]?.currentWeightLbs,
                                isBuiltIn: false
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                exerciseToEdit = exercise
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.archiveExercise(exercise)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Exercises")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingCreateExercise = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateExercise) {
                ExerciseEditorView(viewModel: viewModel, exercise: nil)
            }
            .sheet(item: $exerciseToEdit) { exercise in
                ExerciseEditorView(viewModel: viewModel, exercise: exercise)
            }
            .sheet(item: Binding(
                get: { progressToEdit.map { ProgressEditWrapper(exerciseId: $0.exerciseId, name: $0.name) } },
                set: { progressToEdit = $0.map { ($0.exerciseId, $0.name) } }
            )) { wrapper in
                ExerciseProgressEditorView(
                    viewModel: viewModel,
                    exerciseId: wrapper.exerciseId,
                    exerciseName: wrapper.name
                )
            }
        }
    }
}

struct ProgressEditWrapper: Identifiable {
    let exerciseId: String
    let name: String
    var id: String { exerciseId }
}

struct ExerciseRow: View {
    let name: String
    let muscleGroup: MuscleGroup
    let sets: Int
    let reps: Int
    let weight: Double?
    let isBuiltIn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: muscleGroup.icon)
                .font(.title3)
                .foregroundStyle(isBuiltIn ? .blue : .purple)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(name)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    if isBuiltIn {
                        Text("BUILT-IN")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                Text("\(sets)×\(reps) • \(muscleGroup.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let weight = weight {
                Text("\(Int(weight)) lbs")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

struct ExerciseEditorView: View {
    @Bindable var viewModel: WorkoutViewModel
    let exercise: CustomExercise?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var defaultSets: Int = 3
    @State private var defaultReps: Int = 10
    @State private var weightIncrement: Double = 5
    @State private var isCompound: Bool = true

    var isEditing: Bool { exercise != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    TextField("Exercise Name", text: $name)

                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { group in
                            Label(group.displayName, systemImage: group.icon)
                                .tag(group)
                        }
                    }
                }

                Section("Default Configuration") {
                    Stepper("Sets: \(defaultSets)", value: $defaultSets, in: 1...10)
                    Stepper("Reps: \(defaultReps)", value: $defaultReps, in: 1...20)
                }

                Section("Progression") {
                    HStack {
                        Text("Weight Increment")
                        Spacer()
                        TextField("lbs", value: $weightIncrement, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }

                    Toggle("Compound Movement", isOn: $isCompound)
                }

                if isEditing {
                    Section {
                        if let progress = viewModel.exerciseProgress[exercise!.id.uuidString] {
                            HStack {
                                Text("Current Weight")
                                Spacer()
                                Text("\(Int(progress.currentWeightLbs)) lbs")
                                    .foregroundStyle(.secondary)
                            }

                            if progress.personalRecordLbs > 0 {
                                HStack {
                                    Text("Personal Record")
                                    Spacer()
                                    Text("\(Int(progress.personalRecordLbs)) lbs")
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                    } header: {
                        Text("Progress")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let exercise = exercise {
                    name = exercise.name
                    muscleGroup = exercise.muscleGroup
                    defaultSets = exercise.defaultSets
                    defaultReps = exercise.defaultReps
                    weightIncrement = exercise.weightIncrementLbs
                    isCompound = exercise.isCompound
                }
            }
        }
    }

    private func save() {
        if let exercise = exercise {
            // Update existing
            exercise.name = name
            exercise.muscleGroup = muscleGroup
            exercise.defaultSets = defaultSets
            exercise.defaultReps = defaultReps
            exercise.weightIncrementLbs = weightIncrement
            exercise.isCompound = isCompound
            viewModel.updateExercise(exercise)
        } else {
            // Create new
            viewModel.createExercise(
                name: name,
                muscleGroup: muscleGroup,
                defaultSets: defaultSets,
                defaultReps: defaultReps,
                weightIncrement: weightIncrement,
                isCompound: isCompound
            )
        }
    }
}

struct ExerciseProgressEditorView: View {
    @Bindable var viewModel: WorkoutViewModel
    let exerciseId: String
    let exerciseName: String
    @Environment(\.dismiss) private var dismiss

    @State private var weight: Double = 45

    var progress: ExerciseProgress? {
        viewModel.exerciseProgress[exerciseId]
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Weight") {
                    HStack {
                        Text("\(Int(weight)) lbs")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Spacer()

                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                Button { weight = max(0, weight - 5) } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.bordered)

                                Button { weight += 5 } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 44, height: 44)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let progress = progress {
                    Section("Stats") {
                        HStack {
                            Text("Personal Record")
                            Spacer()
                            Text("\(Int(progress.personalRecordLbs)) lbs")
                                .foregroundStyle(.green)
                        }

                        if let lastDate = progress.lastCompletedDate {
                            HStack {
                                Text("Last Completed")
                                Spacer()
                                Text(lastDate, style: .date)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(exerciseName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.updateExerciseProgress(exerciseId, weight: weight)
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let progress = progress {
                    weight = progress.currentWeightLbs
                }
            }
        }
    }
}

#Preview {
    ExerciseListView(viewModel: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self, CustomExercise.self, CustomWorkoutTemplate.self, configurations: config)
        let vm = WorkoutViewModel(modelContext: container.mainContext)
        vm.loadData()
        return vm
    }())
}
