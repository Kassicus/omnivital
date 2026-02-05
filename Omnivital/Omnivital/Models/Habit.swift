//
//  Habit.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

enum HabitFrequency: String, Codable, Sendable {
    case daily
    case specificDays
}

enum Weekday: Int, Codable, CaseIterable, Sendable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }

    var displayName: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }
}

@Model
final class Habit: Identifiable {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorRaw: String
    var frequencyRaw: String
    var scheduledDays: [Int]
    var isArchived: Bool
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \HabitCompletion.habit) var completions: [HabitCompletion]

    @Transient
    var color: HabitColor {
        get { HabitColor(rawValue: colorRaw) ?? .blue }
        set { colorRaw = newValue.rawValue }
    }

    @Transient
    var frequency: HabitFrequency {
        get { HabitFrequency(rawValue: frequencyRaw) ?? .daily }
        set { frequencyRaw = newValue.rawValue }
    }

    @Transient
    var scheduledWeekdays: [Weekday] {
        get { scheduledDays.compactMap { Weekday(rawValue: $0) } }
        set { scheduledDays = newValue.map { $0.rawValue } }
    }

    func isScheduled(for date: Date) -> Bool {
        if frequency == .daily { return true }
        let weekday = Calendar.current.component(.weekday, from: date)
        return scheduledDays.contains(weekday)
    }

    func isCompleted(on date: Date) -> Bool {
        let start = date.startOfDay
        let end = date.endOfDay
        return completions.contains { $0.completedAt >= start && $0.completedAt <= end }
    }

    @Transient
    var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date().startOfDay

        // If today is scheduled and not yet completed, start from yesterday
        if isScheduled(for: date) && !isCompleted(on: date) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }

        while true {
            if isScheduled(for: date) {
                if isCompleted(on: date) {
                    streak += 1
                } else {
                    break
                }
            }
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previousDay
        }

        return streak
    }

    init(
        id: UUID = UUID(),
        name: String,
        icon: String = "star.fill",
        color: HabitColor = .blue,
        frequency: HabitFrequency = .daily,
        scheduledDays: [Int] = [],
        isArchived: Bool = false,
        createdAt: Date = Date(),
        completions: [HabitCompletion] = []
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorRaw = color.rawValue
        self.frequencyRaw = frequency.rawValue
        self.scheduledDays = scheduledDays
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.completions = completions
    }
}
