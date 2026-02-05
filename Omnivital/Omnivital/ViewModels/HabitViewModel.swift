//
//  HabitViewModel.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class HabitViewModel {
    private let modelContext: ModelContext

    var habits: [Habit] = []
    var todayCompletions: Set<UUID> = []
    var selectedMonth: Date = Date()
    var calendarData: [Date: Double] = [:]
    var isLoading: Bool = false
    var error: Error?

    // Cached values — refreshed on data changes, not recomputed per render
    private(set) var todayScheduledHabits: [Habit] = []
    private(set) var streaks: [UUID: Int] = [:]

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Computed

    var todayTotalCount: Int {
        todayScheduledHabits.count
    }

    var todayCompletedCount: Int {
        todayScheduledHabits.filter { todayCompletions.contains($0.id) }.count
    }

    var todayProgress: Double {
        guard todayTotalCount > 0 else { return 0 }
        return Double(todayCompletedCount) / Double(todayTotalCount)
    }

    // MARK: - Load

    func loadHabits() {
        isLoading = true
        error = nil

        do {
            let descriptor = FetchDescriptor<Habit>(
                predicate: #Predicate { $0.isArchived == false },
                sortBy: [SortDescriptor(\.createdAt, order: .forward)]
            )
            self.habits = try modelContext.fetch(descriptor)
            refreshCachedValues()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func refreshCachedValues() {
        let today = Date()
        todayScheduledHabits = habits.filter { $0.isScheduled(for: today) }
        loadTodayCompletions()
        computeStreaks()
        loadCalendarData()
    }

    private func loadTodayCompletions() {
        let today = Date()
        todayCompletions = Set(
            habits.filter { $0.isCompleted(on: today) }.map { $0.id }
        )
    }

    private func computeStreaks() {
        let calendar = Calendar.current
        var result: [UUID: Int] = [:]

        for habit in habits {
            // Pre-build Set of completion day-starts for O(1) lookup
            let completionDates = Set(habit.completions.map { $0.completedAt.startOfDay })

            var streak = 0
            var date = Date().startOfDay

            if habit.isScheduled(for: date) && !completionDates.contains(date) {
                guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
                    result[habit.id] = 0
                    continue
                }
                date = yesterday
            }

            while true {
                if habit.isScheduled(for: date) {
                    if completionDates.contains(date) {
                        streak += 1
                    } else {
                        break
                    }
                }
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
                date = previousDay
            }

            result[habit.id] = streak
        }

        streaks = result
    }

    func loadCalendarData() {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return
        }

        // Pre-build completion lookup: dayStart -> set of completed habit IDs
        var completionsByDate: [Date: Set<UUID>] = [:]
        for habit in habits {
            for completion in habit.completions {
                let dayStart = completion.completedAt.startOfDay
                completionsByDate[dayStart, default: []].insert(habit.id)
            }
        }

        var data: [Date: Double] = [:]

        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: monthStart) else { continue }
            let dayStart = date.startOfDay

            let scheduled = habits.filter { $0.isScheduled(for: date) }
            guard !scheduled.isEmpty else { continue }

            let completedIDs = completionsByDate[dayStart] ?? []
            let completed = scheduled.filter { completedIDs.contains($0.id) }.count
            data[dayStart] = Double(completed) / Double(scheduled.count)
        }

        calendarData = data
    }

    // MARK: - CRUD

    func createHabit(name: String, icon: String, color: HabitColor, frequency: HabitFrequency, scheduledDays: [Int]) {
        let habit = Habit(
            name: name,
            icon: icon,
            color: color,
            frequency: frequency,
            scheduledDays: scheduledDays
        )

        modelContext.insert(habit)

        do {
            try modelContext.save()
            loadHabits()
        } catch {
            self.error = error
        }
    }

    func updateHabit(_ habit: Habit, name: String, icon: String, color: HabitColor, frequency: HabitFrequency, scheduledDays: [Int]) {
        habit.name = name
        habit.icon = icon
        habit.color = color
        habit.frequency = frequency
        habit.scheduledDays = scheduledDays

        do {
            try modelContext.save()
            loadHabits()
        } catch {
            self.error = error
        }
    }

    func archiveHabit(_ habit: Habit) {
        habit.isArchived = true

        do {
            try modelContext.save()
            loadHabits()
        } catch {
            self.error = error
        }
    }

    func deleteHabit(_ habit: Habit) {
        modelContext.delete(habit)

        do {
            try modelContext.save()
            loadHabits()
        } catch {
            self.error = error
        }
    }

    // MARK: - Toggle

    func toggleCompletion(for habit: Habit) {
        let today = Date()
        let start = today.startOfDay
        let end = today.endOfDay

        if let existing = habit.completions.first(where: { $0.completedAt >= start && $0.completedAt <= end }) {
            modelContext.delete(existing)
            todayCompletions.remove(habit.id)
        } else {
            let completion = HabitCompletion(completedAt: Date(), habit: habit)
            modelContext.insert(completion)
            todayCompletions.insert(habit.id)
        }

        do {
            try modelContext.save()
            computeStreaks()
            loadCalendarData()
        } catch {
            self.error = error
        }
    }

    // MARK: - Calendar Navigation

    func previousMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) {
            selectedMonth = newMonth
            loadCalendarData()
        }
    }

    func nextMonth() {
        if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) {
            selectedMonth = newMonth
            loadCalendarData()
        }
    }
}
