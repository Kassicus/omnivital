//
//  HabitCalendarView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HabitCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: HabitViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Month navigation
                HStack {
                    Button { viewModel.previousMonth() } label: {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(viewModel.selectedMonth, format: .dateTime.month(.wide).year())
                        .font(.headline)

                    Spacer()

                    Button { viewModel.nextMonth() } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // Weekday headers
                HStack(spacing: 0) {
                    ForEach(Array(["S","M","T","W","T","F","S"].enumerated()), id: \.offset) { _, day in
                        Text(day)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal)

                // Calendar grid
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(calendarDays) { item in
                        if let date = item.date {
                            CalendarDayCell(
                                day: Calendar.current.component(.day, from: date),
                                progress: viewModel.calendarData[date.startOfDay] ?? 0,
                                isToday: Calendar.current.isDateInToday(date)
                            )
                        } else {
                            Color.clear
                                .frame(height: 44)
                        }
                    }
                }
                .padding(.horizontal)

                // Legend
                HStack(spacing: 16) {
                    legendItem(progress: 0, label: "None")
                    legendItem(progress: 0.5, label: "Partial")
                    legendItem(progress: 1.0, label: "Complete")
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func legendItem(progress: Double, label: String) -> some View {
        HStack(spacing: 4) {
            CircularProgressView(progress: progress, color: .green, lineWidth: 2)
                .frame(width: 16, height: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var calendarDays: [CalendarItem] {
        let calendar = Calendar.current
        guard let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: viewModel.selectedMonth)),
              let range = calendar.range(of: .day, in: .month, for: viewModel.selectedMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: monthStart)
        let leadingBlanks = firstWeekday - 1

        var items: [CalendarItem] = []

        for i in 0..<leadingBlanks {
            items.append(CalendarItem(id: "blank-\(i)", date: nil))
        }

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                items.append(CalendarItem(id: "day-\(day)", date: date))
            }
        }

        return items
    }
}

private struct CalendarItem: Identifiable {
    let id: String
    let date: Date?
}

struct CalendarDayCell: View {
    let day: Int
    let progress: Double
    let isToday: Bool

    var body: some View {
        ZStack {
            CircularProgressView(progress: progress, color: .green, lineWidth: 3)
                .frame(width: 36, height: 36)

            Text("\(day)")
                .font(.caption2.bold())
                .foregroundStyle(isToday ? .green : .primary)
        }
        .frame(height: 44)
    }
}
