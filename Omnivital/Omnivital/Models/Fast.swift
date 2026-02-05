//
//  Fast.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import SwiftData

enum FastState: String, Codable, Sendable {
    case active
    case completed
    case cancelled
}

enum FastPreset: String, Codable, CaseIterable, Sendable {
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "20:4"
    case twentyThreeOne = "23:1"
    case custom = "Custom"

    var hours: Double {
        switch self {
        case .sixteenEight: return 16
        case .eighteenSix: return 18
        case .twentyFour: return 20
        case .twentyThreeOne: return 23
        case .custom: return 16
        }
    }

    var displayName: String {
        rawValue
    }

    var presetDescription: String {
        switch self {
        case .sixteenEight: return "16 hours fasting, 8 hours eating"
        case .eighteenSix: return "18 hours fasting, 6 hours eating"
        case .twentyFour: return "20 hours fasting, 4 hours eating"
        case .twentyThreeOne: return "23 hours fasting, 1 hour eating"
        case .custom: return "Custom duration"
        }
    }
}

@Model
final class Fast: Identifiable {
    @Attribute(.unique) var id: UUID
    var startTime: Date
    var endTime: Date?
    var targetDurationHours: Double
    var stateRaw: String
    var presetRaw: String?
    var notes: String?

    @Transient
    var state: FastState {
        get { FastState(rawValue: stateRaw) ?? .active }
        set { stateRaw = newValue.rawValue }
    }

    @Transient
    var preset: FastPreset? {
        get { presetRaw.flatMap { FastPreset(rawValue: $0) } }
        set { presetRaw = newValue?.rawValue }
    }

    @Transient
    var targetEndTime: Date {
        startTime.addingTimeInterval(targetDurationHours * 3600)
    }

    @Transient
    var elapsedSeconds: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    @Transient
    var progress: Double {
        let targetSeconds = targetDurationHours * 3600
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    @Transient
    var remainingSeconds: TimeInterval {
        let targetSeconds = targetDurationHours * 3600
        return max(targetSeconds - elapsedSeconds, 0)
    }

    @Transient
    var isComplete: Bool {
        elapsedSeconds >= targetDurationHours * 3600
    }

    @Transient
    var isActive: Bool {
        state == .active
    }

    @Transient
    var durationFormatted: String {
        let hours = Int(elapsedSeconds) / 3600
        let minutes = (Int(elapsedSeconds) % 3600) / 60
        return String(format: "%dh %dm", hours, minutes)
    }

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        targetDurationHours: Double,
        state: FastState = .active,
        preset: FastPreset? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.targetDurationHours = targetDurationHours
        self.stateRaw = state.rawValue
        self.presetRaw = preset?.rawValue
        self.notes = notes
    }
}
