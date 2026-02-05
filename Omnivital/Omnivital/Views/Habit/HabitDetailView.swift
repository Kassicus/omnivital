//
//  HabitDetailView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HabitDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let habit: Habit
    let viewModel: HabitViewModel

    @State private var showEditor = false
    @State private var showArchiveConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: habit.icon)
                            .font(.system(size: 40))
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(habit.color.color)
                            .clipShape(Circle())

                        Text(habit.name)
                            .font(.title2.bold())
                    }
                    .padding(.top, 20)

                    // Stats
                    HStack(spacing: 0) {
                        statItem(value: "\(viewModel.streaks[habit.id] ?? 0)", label: "Streak", icon: "flame.fill")
                        Divider().frame(height: 40)
                        statItem(value: "\(habit.completions.count)", label: "Total", icon: "checkmark.circle")
                        Divider().frame(height: 40)
                        statItem(value: habit.createdAt.formatted(.dateTime.month(.abbreviated).day()), label: "Created", icon: "calendar")
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Recent completions
                    RecentCompletionsView(habit: habit)
                        .padding()
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)

                    // Archive button
                    Button(role: .destructive) {
                        showArchiveConfirmation = true
                    } label: {
                        Label("Archive Habit", systemImage: "archivebox")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Habit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { showEditor = true }
                }
            }
            .sheet(isPresented: $showEditor) {
                HabitEditorView(viewModel: viewModel, habit: habit)
            }
            .confirmationDialog("Archive Habit?", isPresented: $showArchiveConfirmation, titleVisibility: .visible) {
                Button("Archive", role: .destructive) {
                    viewModel.archiveHabit(habit)
                    dismiss()
                }
            } message: {
                Text("This habit will be hidden from your dashboard. Completion data will be preserved.")
            }
        }
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(habit.color.color)
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
