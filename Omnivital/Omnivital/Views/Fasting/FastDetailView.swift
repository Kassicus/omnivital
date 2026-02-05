//
//  FastDetailView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct FastDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let fast: Fast
    let onSave: (Date, Date?, String?) -> Void
    let onDelete: () -> Void

    @State private var startTime: Date
    @State private var endTime: Date
    @State private var notes: String
    @State private var showDeleteConfirmation = false

    init(fast: Fast, onSave: @escaping (Date, Date?, String?) -> Void, onDelete: @escaping () -> Void) {
        self.fast = fast
        self.onSave = onSave
        self.onDelete = onDelete
        self._startTime = State(initialValue: fast.startTime)
        self._endTime = State(initialValue: fast.endTime ?? Date())
        self._notes = State(initialValue: fast.notes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Status") {
                    HStack {
                        Text("State")
                        Spacer()
                        StatusBadge(state: fast.state)
                    }

                    if let preset = fast.preset {
                        HStack {
                            Text("Preset")
                            Spacer()
                            Text(preset.displayName)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Text("Target Duration")
                        Spacer()
                        Text("\(Int(fast.targetDurationHours)) hours")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Times") {
                    DatePicker("Start Time", selection: $startTime)

                    if fast.state != .active {
                        DatePicker("End Time", selection: $endTime)
                    }
                }

                Section("Duration") {
                    HStack {
                        Text("Elapsed")
                        Spacer()
                        Text(fast.durationFormatted)
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Progress")
                        Spacer()
                        Text(String(format: "%.0f%%", fast.progress * 100))
                            .foregroundStyle(fast.isComplete ? .green : .orange)
                    }
                }

                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Delete Fast", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Fast Details")
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
                        let finalEndTime = fast.state == .active ? nil : endTime
                        onSave(startTime, finalEndTime, notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Delete Fast", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    onDelete()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this fast? This action cannot be undone.")
            }
        }
    }
}

#Preview {
    FastDetailView(
        fast: Fast(
            startTime: Date().addingTimeInterval(-3600 * 18),
            endTime: Date().addingTimeInterval(-3600 * 2),
            targetDurationHours: 16,
            state: .completed,
            preset: .sixteenEight,
            notes: "Felt great during this fast!"
        ),
        onSave: { _, _, _ in },
        onDelete: {}
    )
}
