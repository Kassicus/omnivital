//
//  TemplateListView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct TemplateListView: View {
    @Bindable var viewModel: WorkoutViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateTemplate = false
    @State private var templateToEdit: CustomWorkoutTemplate?

    var body: some View {
        NavigationStack {
            List {
                // Built-in templates
                Section("StrongLifts 5×5") {
                    ForEach(WorkoutTemplate.defaultTemplates, id: \.id) { template in
                        TemplateRow(
                            name: template.name,
                            color: template.color,
                            exerciseNames: template.exercises.map { $0.name },
                            isBuiltIn: true
                        )
                    }
                }

                // Custom templates
                if !viewModel.customTemplates.filter({ !$0.isArchived }).isEmpty {
                    Section("Custom Workouts") {
                        ForEach(viewModel.customTemplates.filter { !$0.isArchived }) { template in
                            TemplateRow(
                                name: template.name,
                                color: template.color,
                                exerciseNames: template.exerciseConfigs.compactMap { config in
                                    viewModel.getExerciseDefinition(byId: config.exerciseId)?.name
                                },
                                isBuiltIn: false
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                templateToEdit = template
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.archiveTemplate(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Workouts")
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
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                TemplateEditorView(viewModel: viewModel, template: nil)
            }
            .sheet(item: $templateToEdit) { template in
                TemplateEditorView(viewModel: viewModel, template: template)
            }
        }
    }
}

struct TemplateRow: View {
    let name: String
    let color: WorkoutTemplate.TemplateColor
    let exerciseNames: [String]
    let isBuiltIn: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.color)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(name.prefix(1))
                        .font(.headline)
                        .foregroundStyle(.white)
                }

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

                Text(exerciseNames.joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if !isBuiltIn {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

struct TemplateEditorView: View {
    @Bindable var viewModel: WorkoutViewModel
    let template: CustomWorkoutTemplate?
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedColor: WorkoutTemplate.TemplateColor = .blue
    @State private var exerciseConfigs: [ExerciseConfig] = []
    @State private var showingAddExercise = false

    var isEditing: Bool { template != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Details") {
                    TextField("Workout Name", text: $name)

                    Picker("Color", selection: $selectedColor) {
                        ForEach([WorkoutTemplate.TemplateColor.blue, .orange, .green, .purple, .red], id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(color.color)
                                    .frame(width: 20, height: 20)
                                Text(color.rawValue.capitalized)
                            }
                            .tag(color)
                        }
                    }
                }

                Section {
                    ForEach(exerciseConfigs) { config in
                        if let exercise = viewModel.getExerciseDefinition(byId: config.exerciseId) {
                            ExerciseConfigRow(
                                exercise: exercise,
                                config: config,
                                onUpdate: { updatedConfig in
                                    if let index = exerciseConfigs.firstIndex(where: { $0.id == config.id }) {
                                        exerciseConfigs[index] = updatedConfig
                                    }
                                }
                            )
                        }
                    }
                    .onDelete { indexSet in
                        exerciseConfigs.remove(atOffsets: indexSet)
                        reorderConfigs()
                    }
                    .onMove { from, to in
                        exerciseConfigs.move(fromOffsets: from, toOffset: to)
                        reorderConfigs()
                    }

                    Button {
                        showingAddExercise = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if exerciseConfigs.isEmpty {
                        Text("Add at least one exercise to your workout.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Workout" : "New Workout")
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
                    .disabled(name.isEmpty || exerciseConfigs.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddExercise) {
                AddExerciseToTemplateView(
                    viewModel: viewModel,
                    onAdd: { exerciseId, isCustom in
                        let exercise = viewModel.getExerciseDefinition(byId: exerciseId)
                        let config = ExerciseConfig(
                            exerciseId: exerciseId,
                            isCustom: isCustom,
                            sets: exercise?.defaultSets ?? 3,
                            reps: exercise?.defaultReps ?? 10,
                            order: exerciseConfigs.count
                        )
                        exerciseConfigs.append(config)
                    }
                )
            }
            .onAppear {
                if let template = template {
                    name = template.name
                    selectedColor = template.color
                    exerciseConfigs = template.exerciseConfigs
                }
            }
        }
    }

    private func reorderConfigs() {
        for (index, _) in exerciseConfigs.enumerated() {
            exerciseConfigs[index].order = index
        }
    }

    private func save() {
        if let template = template {
            // Update existing
            template.name = name
            template.color = selectedColor
            template.exerciseConfigs = exerciseConfigs
            viewModel.updateTemplate(template)
        } else {
            // Create new
            viewModel.createTemplate(
                name: name,
                color: selectedColor,
                exercises: exerciseConfigs
            )
        }
    }
}

struct ExerciseConfigRow: View {
    let exercise: ExerciseDefinition
    let config: ExerciseConfig
    let onUpdate: (ExerciseConfig) -> Void

    @State private var sets: Int
    @State private var reps: Int

    init(exercise: ExerciseDefinition, config: ExerciseConfig, onUpdate: @escaping (ExerciseConfig) -> Void) {
        self.exercise = exercise
        self.config = config
        self.onUpdate = onUpdate
        self._sets = State(initialValue: config.sets)
        self._reps = State(initialValue: config.reps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: exercise.muscleGroup.icon)
                    .foregroundStyle(.blue)
                Text(exercise.name)
                    .fontWeight(.medium)
                Spacer()
            }

            HStack {
                Text("Sets:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper("\(sets)", value: $sets, in: 1...10)
                    .labelsHidden()
                    .onChange(of: sets) { _, newValue in
                        var updated = config
                        updated.sets = newValue
                        onUpdate(updated)
                    }

                Spacer()

                Text("Reps:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Stepper("\(reps)", value: $reps, in: 1...20)
                    .labelsHidden()
                    .onChange(of: reps) { _, newValue in
                        var updated = config
                        updated.reps = newValue
                        onUpdate(updated)
                    }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddExerciseToTemplateView: View {
    @Bindable var viewModel: WorkoutViewModel
    let onAdd: (String, Bool) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Built-in Exercises") {
                    ForEach(ExerciseDefinition.allExercises, id: \.id) { exercise in
                        Button {
                            onAdd(exercise.id, false)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: exercise.muscleGroup.icon)
                                    .foregroundStyle(.blue)
                                    .frame(width: 30)

                                VStack(alignment: .leading) {
                                    Text(exercise.name)
                                        .foregroundStyle(.primary)
                                    Text("\(exercise.defaultSets)×\(exercise.defaultReps)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()
                            }
                        }
                    }
                }

                if !viewModel.customExercises.filter({ !$0.isArchived }).isEmpty {
                    Section("Custom Exercises") {
                        ForEach(viewModel.customExercises.filter { !$0.isArchived }) { exercise in
                            Button {
                                onAdd(exercise.id.uuidString, true)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: exercise.muscleGroup.icon)
                                        .foregroundStyle(.purple)
                                        .frame(width: 30)

                                    VStack(alignment: .leading) {
                                        Text(exercise.name)
                                            .foregroundStyle(.primary)
                                        Text("\(exercise.defaultSets)×\(exercise.defaultReps)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Exercise")
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
        }
    }
}

#Preview {
    TemplateListView(viewModel: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self, CustomExercise.self, CustomWorkoutTemplate.self, configurations: config)
        let vm = WorkoutViewModel(modelContext: container.mainContext)
        vm.loadData()
        return vm
    }())
}
