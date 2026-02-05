//
//  HabitCompletion.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Model
final class HabitCompletion: Identifiable {
    @Attribute(.unique) var id: UUID
    var completedAt: Date
    var habit: Habit?

    init(id: UUID = UUID(), completedAt: Date = Date(), habit: Habit? = nil) {
        self.id = id
        self.completedAt = completedAt
        self.habit = habit
    }
}
