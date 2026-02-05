//
//  HabitRowView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let streak: Int
    let onToggle: () -> Void
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkmark toggle — its own Button so it receives taps independently
            Button(action: onToggle) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isCompleted ? habit.color.color : .secondary)
            }
            .buttonStyle(.plain)

            // Row content — separate Button for navigation
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: habit.icon)
                        .font(.body)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(habit.color.color)
                        .clipShape(Circle())

                    // Name and frequency
                    VStack(alignment: .leading, spacing: 2) {
                        Text(habit.name)
                            .font(.body)
                            .strikethrough(isCompleted, color: .secondary)
                            .foregroundStyle(isCompleted ? .secondary : .primary)

                        Text(frequencyText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Streak badge
                    if streak > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundStyle(.orange)
                            Text("\(streak)")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var frequencyText: String {
        if habit.frequency == .daily {
            return "Every day"
        }
        let days = habit.scheduledWeekdays.map { $0.shortName }
        return days.joined(separator: ", ")
    }
}
