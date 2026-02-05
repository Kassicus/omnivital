//
//  FastingViewModel.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

@Observable
@MainActor
final class FastingViewModel {
    private let modelContext: ModelContext

    var activeFast: Fast?
    var recentFasts: [Fast] = []
    var fastsForSelectedDate: [Fast] = []
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var error: Error?

    var selectedPreset: FastPreset = .sixteenEight
    var customDurationHours: Double = 16

    var targetDurationHours: Double {
        selectedPreset == .custom ? customDurationHours : selectedPreset.hours
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadFasts() {
        isLoading = true
        error = nil

        do {
            // Load active fast
            let activeDescriptor = FetchDescriptor<Fast>(
                predicate: #Predicate { $0.stateRaw == "active" },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            let activeFasts = try modelContext.fetch(activeDescriptor)
            self.activeFast = activeFasts.first

            // Load recent fasts (last 30 days, completed or cancelled)
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            let recentDescriptor = FetchDescriptor<Fast>(
                predicate: #Predicate { fast in
                    fast.stateRaw != "active" && fast.startTime >= thirtyDaysAgo
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            self.recentFasts = try modelContext.fetch(recentDescriptor)

            // Load fasts for selected date
            loadFastsForSelectedDate()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func loadFastsForSelectedDate() {
        let startOfDay = selectedDate.startOfDay
        let endOfDay = selectedDate.endOfDay

        do {
            let descriptor = FetchDescriptor<Fast>(
                predicate: #Predicate { fast in
                    fast.startTime >= startOfDay && fast.startTime <= endOfDay
                },
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )
            self.fastsForSelectedDate = try modelContext.fetch(descriptor)
        } catch {
            self.error = error
        }
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        loadFastsForSelectedDate()
    }

    func startFast() {
        let fast = Fast(
            targetDurationHours: targetDurationHours,
            preset: selectedPreset
        )

        modelContext.insert(fast)

        do {
            try modelContext.save()
            activeFast = fast
            loadFasts()
        } catch {
            self.error = error
        }
    }

    func completeFast() {
        guard let fast = activeFast else { return }

        fast.endTime = Date()
        fast.state = .completed

        do {
            try modelContext.save()
            activeFast = nil
            loadFasts()
        } catch {
            self.error = error
        }
    }

    func cancelFast() {
        guard let fast = activeFast else { return }

        fast.endTime = Date()
        fast.state = .cancelled

        do {
            try modelContext.save()
            activeFast = nil
            loadFasts()
        } catch {
            self.error = error
        }
    }

    func deleteFast(_ fast: Fast) {
        modelContext.delete(fast)

        do {
            try modelContext.save()
            if fast.id == activeFast?.id {
                activeFast = nil
            }
            loadFasts()
        } catch {
            self.error = error
        }
    }

    func updateFast(_ fast: Fast, startTime: Date? = nil, endTime: Date? = nil, notes: String? = nil) {
        if let startTime = startTime {
            fast.startTime = startTime
        }
        if let endTime = endTime {
            fast.endTime = endTime
        }
        if let notes = notes {
            fast.notes = notes
        }

        do {
            try modelContext.save()
            loadFasts()
        } catch {
            self.error = error
        }
    }
}
