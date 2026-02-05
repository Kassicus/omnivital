//
//  HabitDashboardView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HabitDashboardView: View {
    let viewModel: HabitViewModel
    @State private var selectedHabit: Habit?

    var body: some View {
        Group {
            if viewModel.habits.isEmpty {
                ContentUnavailableView(
                    "No Habits Yet",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Tap + to create your first habit.")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        TodayProgressCard(
                            progress: viewModel.todayProgress,
                            completedCount: viewModel.todayCompletedCount,
                            totalCount: viewModel.todayTotalCount
                        )
                        .padding(.horizontal)

                        if viewModel.todayScheduledHabits.isEmpty {
                            Text("No habits scheduled for today.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(viewModel.todayScheduledHabits, id: \.id) { habit in
                                    HabitRowView(
                                        habit: habit,
                                        isCompleted: viewModel.todayCompletions.contains(habit.id),
                                        streak: viewModel.streaks[habit.id] ?? 0,
                                        onToggle: { viewModel.toggleCompletion(for: habit) },
                                        onTap: { selectedHabit = habit }
                                    )

                                    if habit.id != viewModel.todayScheduledHabits.last?.id {
                                        Divider()
                                            .padding(.leading, 60)
                                    }
                                }
                            }
                            .background(Color(uiColor: .secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }

                        if let error = viewModel.error {
                            Text(error.localizedDescription)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .padding()
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(.top, 8)
                }
            }
        }
        .sheet(item: $selectedHabit) { habit in
            HabitDetailView(habit: habit, viewModel: viewModel)
        }
    }
}
