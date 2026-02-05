//
//  ActiveWorkoutView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData
import Combine

struct ActiveWorkoutView: View {
    @Bindable var viewModel: WorkoutViewModel
    @State private var showingCancelConfirmation = false
    @State private var showingFinishConfirmation = false
    @State private var workoutTime = Date()
    @State private var selectedReps: Int = 5

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            // Workout timer header
            WorkoutTimerHeader(
                workout: viewModel.activeWorkout,
                currentTime: workoutTime
            )

            if viewModel.isResting {
                // Rest timer view
                RestTimerView(
                    timeRemaining: viewModel.restTimeRemaining,
                    onSkip: { viewModel.skipRest() },
                    onAddTime: { viewModel.addRestTime(60) }
                )
            } else if viewModel.isWorkoutComplete {
                // Workout complete view
                WorkoutCompleteView(
                    workout: viewModel.activeWorkout,
                    onFinish: { viewModel.finishWorkout() }
                )
            } else {
                // Current set view
                if let exercise = viewModel.currentExercise,
                   let set = viewModel.currentSet,
                   let exerciseDef = exercise.exercise {
                    CurrentSetView(
                        exercise: exerciseDef,
                        workoutExercise: exercise,
                        set: set,
                        setIndex: viewModel.currentSetIndex,
                        totalSets: exercise.sets.count,
                        selectedReps: $selectedReps,
                        onComplete: {
                            viewModel.completeSet(reps: selectedReps)
                            selectedReps = set.targetReps
                        },
                        onFail: {
                            viewModel.failSet()
                            selectedReps = set.targetReps
                        },
                        onWeightChange: { newWeight in
                            viewModel.updateSetWeight(set, weight: newWeight)
                        }
                    )
                }
            }

            Spacer()

            // Exercise progress bar
            if let workout = viewModel.activeWorkout {
                ExerciseProgressBar(
                    exercises: workout.exercises.sorted { $0.order < $1.order },
                    currentIndex: viewModel.currentExerciseIndex
                )
                .padding()
            }
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    showingCancelConfirmation = true
                }
                .foregroundStyle(.red)
            }

            if viewModel.isWorkoutComplete {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish") {
                        viewModel.finishWorkout()
                    }
                }
            }
        }
        .confirmationDialog("Cancel Workout?", isPresented: $showingCancelConfirmation) {
            Button("Cancel Workout", role: .destructive) {
                viewModel.cancelWorkout()
            }
            Button("Keep Going", role: .cancel) {}
        } message: {
            Text("Your progress will be lost.")
        }
        .onReceive(timer) { _ in
            workoutTime = Date()
        }
        .onAppear {
            if let set = viewModel.currentSet {
                selectedReps = set.targetReps
            }
        }
    }
}

struct WorkoutTimerHeader: View {
    let workout: Workout?
    let currentTime: Date

    private var elapsedTime: TimeInterval {
        guard let workout = workout else { return 0 }
        return currentTime.timeIntervalSince(workout.startTime)
    }

    private var formattedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        HStack {
            if let template = workout?.template {
                HStack(spacing: 8) {
                    Circle()
                        .fill(template.color.color)
                        .frame(width: 32, height: 32)
                        .overlay {
                            Text(template.name.last.map { String($0) } ?? "")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }

                    Text(template.name)
                        .font(.headline)
                }
            }

            Spacer()

            Label(formattedTime, systemImage: "timer")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
    }
}

struct CurrentSetView: View {
    let exercise: ExerciseDefinition
    let workoutExercise: WorkoutExercise
    let set: WorkoutSet
    let setIndex: Int
    let totalSets: Int
    @Binding var selectedReps: Int
    let onComplete: () -> Void
    let onFail: () -> Void
    let onWeightChange: (Double) -> Void

    @State private var showWeightPicker = false

    var body: some View {
        VStack(spacing: 24) {
            // Exercise name and set count
            VStack(spacing: 8) {
                Text(exercise.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Set \(setIndex + 1) of \(totalSets)")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 32)

            // Weight display (tappable to edit)
            Button {
                showWeightPicker = true
            } label: {
                VStack(spacing: 4) {
                    Text("\(Int(set.weight))")
                        .font(.system(size: 72, weight: .bold, design: .rounded))

                    Text("lbs")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Plate calculator
            PlateCalculatorInline(totalWeight: set.weight)
                .padding(.top, 4)

            // Reps selector
            VStack(spacing: 12) {
                Text("Reps Completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 16) {
                    ForEach(0...set.targetReps, id: \.self) { reps in
                        Button {
                            selectedReps = reps
                        } label: {
                            Text("\(reps)")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(width: 50, height: 50)
                                .background(selectedReps == reps ? Color.blue : Color.gray.opacity(0.2))
                                .foregroundStyle(selectedReps == reps ? .white : .primary)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Completed sets indicator
            HStack(spacing: 8) {
                ForEach(workoutExercise.sets.sorted { $0.setNumber < $1.setNumber }, id: \.id) { s in
                    Circle()
                        .fill(setColor(for: s))
                        .frame(width: 12, height: 12)
                }
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: onComplete) {
                    Label(selectedReps == set.targetReps ? "Complete Set" : "Log \(selectedReps) Reps", systemImage: "checkmark")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedReps == set.targetReps ? .green : .orange)

                Button(action: onFail) {
                    Label("Failed Set", systemImage: "xmark")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .tint(.red)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showWeightPicker) {
            WeightPickerSheet(
                currentWeight: set.weight,
                onSave: { newWeight in
                    onWeightChange(newWeight)
                }
            )
        }
    }

    private func setColor(for set: WorkoutSet) -> Color {
        if set.completed {
            return set.failed ? .orange : .green
        } else if set.failed {
            return .red
        } else if set.id == self.set.id {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }
}

struct RestTimerView: View {
    let timeRemaining: Int
    let onSkip: () -> Void
    let onAddTime: () -> Void

    private var progress: Double {
        1.0 - (Double(timeRemaining) / 180.0)
    }

    private var formattedTime: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Rest")
                .font(.title2)
                .foregroundStyle(.secondary)

            ZStack {
                CircularProgressView(
                    progress: progress,
                    color: .blue,
                    lineWidth: 12
                )
                .frame(width: 200, height: 200)

                Text(formattedTime)
                    .font(.system(size: 56, weight: .bold, design: .monospaced))
            }

            HStack(spacing: 20) {
                Button(action: onAddTime) {
                    Label("+1 min", systemImage: "plus")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)

                Button(action: onSkip) {
                    Label("Skip", systemImage: "forward.fill")
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
    }
}

struct WorkoutCompleteView: View {
    let workout: Workout?
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("Workout Complete!")
                .font(.title)
                .fontWeight(.bold)

            if let workout = workout {
                VStack(spacing: 8) {
                    Text("Duration: \(workout.durationFormatted)")
                    Text("Sets: \(workout.completedSetsCount)/\(workout.totalSetsCount)")
                    Text("Volume: \(Int(workout.totalVolume)) lbs")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Button(action: onFinish) {
                Label("Finish Workout", systemImage: "flag.checkered")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

struct ExerciseProgressBar: View {
    let exercises: [WorkoutExercise]
    let currentIndex: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(exercises.enumerated()), id: \.element.id) { index, exercise in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: exercise, at: index))
                        .frame(height: index == currentIndex ? 8 : 6)

                    if let exerciseDef = exercise.exercise {
                        Text(abbreviation(for: exerciseDef.name))
                            .font(.caption2)
                            .foregroundStyle(index == currentIndex ? .primary : .secondary)
                    }
                }
            }
        }
    }

    private func barColor(for exercise: WorkoutExercise, at index: Int) -> Color {
        if exercise.allSetsCompleted {
            return exercise.failedSetsCount > 0 ? .orange : .green
        } else if index == currentIndex {
            return .blue
        } else {
            return .gray.opacity(0.3)
        }
    }

    private func abbreviation(for name: String) -> String {
        let words = name.split(separator: " ")
        if words.count > 1 {
            return words.map { String($0.prefix(1)) }.joined()
        }
        return String(name.prefix(3))
    }
}

struct WeightPickerSheet: View {
    let currentWeight: Double
    let onSave: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var weight: Double

    init(currentWeight: Double, onSave: @escaping (Double) -> Void) {
        self.currentWeight = currentWeight
        self.onSave = onSave
        self._weight = State(initialValue: currentWeight)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("\(Int(weight)) lbs")
                    .font(.system(size: 56, weight: .bold, design: .rounded))

                HStack(spacing: 16) {
                    Button { weight = max(0, weight - 5) } label: {
                        Image(systemName: "minus")
                            .font(.title2)
                            .frame(width: 60, height: 60)
                    }
                    .buttonStyle(.bordered)

                    Button { weight = max(0, weight - 2.5) } label: {
                        Text("-2.5")
                            .font(.headline)
                            .frame(width: 60, height: 60)
                    }
                    .buttonStyle(.bordered)

                    Button { weight += 2.5 } label: {
                        Text("+2.5")
                            .font(.headline)
                            .frame(width: 60, height: 60)
                    }
                    .buttonStyle(.bordered)

                    Button { weight += 5 } label: {
                        Image(systemName: "plus")
                            .font(.title2)
                            .frame(width: 60, height: 60)
                    }
                    .buttonStyle(.bordered)
                }

                // Plate calculator visualization
                PlateCalculatorView(totalWeight: weight)
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 32)
            .navigationTitle("Adjust Weight")
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
                        onSave(weight)
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Active Workout") {
    ActiveWorkoutView(viewModel: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Workout.self, WorkoutExercise.self, WorkoutSet.self, ExerciseProgress.self, CustomExercise.self, CustomWorkoutTemplate.self, configurations: config)
        let vm = WorkoutViewModel(modelContext: container.mainContext)
        vm.startWorkout(template: .builtIn(.workoutA))
        return vm
    }())
}

#Preview("Rest Timer") {
    RestTimerView(
        timeRemaining: 145,
        onSkip: {},
        onAddTime: {}
    )
}
