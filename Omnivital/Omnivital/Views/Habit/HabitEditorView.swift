//
//  HabitEditorView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HabitEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let viewModel: HabitViewModel
    let habit: Habit?

    @State private var name: String
    @State private var selectedIcon: String
    @State private var selectedColor: HabitColor
    @State private var frequency: HabitFrequency
    @State private var selectedDays: Set<Weekday>
    @State private var showDeleteConfirmation = false

    var isEditing: Bool { habit != nil }

    init(viewModel: HabitViewModel, habit: Habit? = nil) {
        self.viewModel = viewModel
        self.habit = habit
        _name = State(initialValue: habit?.name ?? "")
        _selectedIcon = State(initialValue: habit?.icon ?? "star.fill")
        _selectedColor = State(initialValue: habit?.color ?? .blue)
        _frequency = State(initialValue: habit?.frequency ?? .daily)
        _selectedDays = State(initialValue: Set(habit?.scheduledWeekdays ?? []))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Habit name", text: $name)
                }

                Section("Icon") {
                    IconPickerGrid(selectedIcon: $selectedIcon, accentColor: selectedColor.color)
                }

                Section("Color") {
                    ColorPickerGrid(selectedColor: $selectedColor)
                }

                Section("Frequency") {
                    Picker("Frequency", selection: $frequency) {
                        Text("Every Day").tag(HabitFrequency.daily)
                        Text("Specific Days").tag(HabitFrequency.specificDays)
                    }
                    .pickerStyle(.segmented)

                    if frequency == .specificDays {
                        WeekdayPickerView(selectedDays: $selectedDays)
                            .padding(.vertical, 4)
                    }
                }

                if isEditing {
                    Section {
                        Button("Delete Habit", role: .destructive) {
                            showDeleteConfirmation = true
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Habit" : "New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("Delete Habit?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let habit { viewModel.deleteHabit(habit) }
                    dismiss()
                }
            } message: {
                Text("This will permanently delete this habit and all its completion data.")
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let days = frequency == .specificDays ? selectedDays.map { $0.rawValue } : []

        if let habit {
            viewModel.updateHabit(habit, name: trimmedName, icon: selectedIcon, color: selectedColor, frequency: frequency, scheduledDays: days)
        } else {
            viewModel.createHabit(name: trimmedName, icon: selectedIcon, color: selectedColor, frequency: frequency, scheduledDays: days)
        }

        dismiss()
    }
}
