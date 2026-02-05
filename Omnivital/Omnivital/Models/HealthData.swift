//
//  HealthData.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation

struct HeartRateData {
    let current: Double?
    let resting: Double?
    let walkingAverage: Double?
    let timestamp: Date?
}

enum SleepStage: String {
    case inBed = "InBed"
    case asleepUnspecified = "AsleepUnspecified"
    case asleepCore = "AsleepCore"
    case asleepDeep = "AsleepDeep"
    case asleepREM = "AsleepREM"
    case awake = "Awake"

    var displayName: String {
        switch self {
        case .inBed: return "In Bed"
        case .asleepUnspecified: return "Asleep"
        case .asleepCore: return "Core Sleep"
        case .asleepDeep: return "Deep Sleep"
        case .asleepREM: return "REM Sleep"
        case .awake: return "Awake"
        }
    }
}

struct SleepSegment: Identifiable {
    let id = UUID()
    let stage: SleepStage
    let startDate: Date
    let endDate: Date

    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var durationHours: Double {
        duration / 3600
    }
}

struct SleepData {
    let segments: [SleepSegment]
    let totalSleepHours: Double
    let inBedHours: Double
    let sleepEfficiency: Double?

    init(segments: [SleepSegment] = []) {
        self.segments = segments

        let sleepSegments = segments.filter { segment in
            switch segment.stage {
            case .asleepUnspecified, .asleepCore, .asleepDeep, .asleepREM:
                return true
            default:
                return false
            }
        }

        self.totalSleepHours = sleepSegments.reduce(0) { $0 + $1.durationHours }
        self.inBedHours = segments.reduce(0) { $0 + $1.durationHours }

        if inBedHours > 0 {
            self.sleepEfficiency = totalSleepHours / inBedHours
        } else {
            self.sleepEfficiency = nil
        }
    }
}
