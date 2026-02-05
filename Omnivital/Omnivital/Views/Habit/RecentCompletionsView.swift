//
//  RecentCompletionsView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct RecentCompletionsView: View {
    let habit: Habit

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 14 Days")
                .font(.subheadline.bold())

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(recentDays, id: \.self) { date in
                    let completed = habit.isCompleted(on: date)
                    let scheduled = habit.isScheduled(for: date)

                    ZStack {
                        Circle()
                            .fill(completed ? habit.color.color : (scheduled ? Color.secondary.opacity(0.15) : Color.clear))
                            .frame(width: 32, height: 32)

                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.caption2.bold())
                            .foregroundStyle(completed ? .white : (scheduled ? .primary : .secondary.opacity(0.5)))
                    }
                }
            }
        }
    }

    private var recentDays: [Date] {
        let calendar = Calendar.current
        let today = Date().startOfDay
        return (0..<14).reversed().compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }
    }
}
