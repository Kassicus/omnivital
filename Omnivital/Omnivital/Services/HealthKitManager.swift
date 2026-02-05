//
//  HealthKitManager.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation
import HealthKit

enum HealthKitAuthorizationStatus {
    case notDetermined
    case authorized
    case denied
    case unavailable
}

@Observable
@MainActor
final class HealthKitManager {
    private let healthStore: HKHealthStore?

    var authorizationStatus: HealthKitAuthorizationStatus = .notDetermined
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private let typesToRead: Set<HKObjectType> = {
        var types = Set<HKObjectType>()

        // Quantity types
        if let steps = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            types.insert(steps)
        }
        if let calories = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(calories)
        }
        if let heartRate = HKQuantityType.quantityType(forIdentifier: .heartRate) {
            types.insert(heartRate)
        }
        if let restingHR = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            types.insert(restingHR)
        }
        if let walkingHR = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) {
            types.insert(walkingHR)
        }
        if let distance = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            types.insert(distance)
        }
        if let standTime = HKQuantityType.quantityType(forIdentifier: .appleStandTime) {
            types.insert(standTime)
        }

        // Category types
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }

        return types
    }()

    init() {
        if HKHealthStore.isHealthDataAvailable() {
            self.healthStore = HKHealthStore()
        } else {
            self.healthStore = nil
            self.authorizationStatus = .unavailable
        }
    }

    // MARK: - Authorization

    func checkAuthorizationStatus() {
        guard let healthStore = healthStore else {
            authorizationStatus = .unavailable
            return
        }

        // Check authorization status for step count as a representative type
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return
        }

        let status = healthStore.authorizationStatus(for: stepType)
        switch status {
        case .notDetermined:
            authorizationStatus = .notDetermined
        case .sharingAuthorized:
            authorizationStatus = .authorized
        case .sharingDenied:
            // Note: HealthKit doesn't tell us if READ was denied, only WRITE
            // We treat sharingDenied as potentially authorized for reading
            authorizationStatus = .authorized
        @unknown default:
            authorizationStatus = .notDetermined
        }
    }

    func requestAuthorization() async throws {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        authorizationStatus = .authorized
    }

    // MARK: - Data Fetching

    func fetchSteps(for date: Date) async throws -> Double {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchCumulativeSum(
            for: stepType,
            unit: .count(),
            startDate: date.startOfDay,
            endDate: date.endOfDay
        )
    }

    func fetchActiveCalories(for date: Date) async throws -> Double {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchCumulativeSum(
            for: calorieType,
            unit: .kilocalorie(),
            startDate: date.startOfDay,
            endDate: date.endOfDay
        )
    }

    func fetchDistance(for date: Date) async throws -> Double {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchCumulativeSum(
            for: distanceType,
            unit: .mile(),
            startDate: date.startOfDay,
            endDate: date.endOfDay
        )
    }

    func fetchStandHours(for date: Date) async throws -> Double {
        guard let standType = HKQuantityType.quantityType(forIdentifier: .appleStandTime) else {
            throw HealthKitError.typeNotAvailable
        }

        let minutes = try await fetchCumulativeSum(
            for: standType,
            unit: .minute(),
            startDate: date.startOfDay,
            endDate: date.endOfDay
        )

        return minutes / 60.0 // Convert to hours
    }

    func fetchHeartRate() async throws -> HeartRateData {
        async let current = fetchMostRecentHeartRate()
        async let resting = fetchRestingHeartRate()
        async let walking = fetchWalkingHeartRateAverage()

        return try await HeartRateData(
            current: current,
            resting: resting,
            walkingAverage: walking,
            timestamp: Date()
        )
    }

    func fetchSleepAnalysis(for date: Date) async throws -> SleepData {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            throw HealthKitError.typeNotAvailable
        }

        let startDate = date.startOfSleepQuery
        let endDate = date.endOfDay

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: SleepData())
                    return
                }

                let segments = samples.compactMap { sample -> SleepSegment? in
                    let stage: SleepStage
                    switch sample.value {
                    case HKCategoryValueSleepAnalysis.inBed.rawValue:
                        stage = .inBed
                    case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                        stage = .asleepUnspecified
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        stage = .asleepCore
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        stage = .asleepDeep
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        stage = .asleepREM
                    case HKCategoryValueSleepAnalysis.awake.rawValue:
                        stage = .awake
                    default:
                        return nil
                    }

                    return SleepSegment(
                        stage: stage,
                        startDate: sample.startDate,
                        endDate: sample.endDate
                    )
                }

                continuation.resume(returning: SleepData(segments: segments))
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Background Delivery

    func enableBackgroundDelivery() async {
        guard let healthStore = healthStore else { return }

        for type in typesToRead {
            guard let sampleType = type as? HKSampleType else { continue }

            do {
                try await healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate)
            } catch {
                print("Failed to enable background delivery for \(sampleType): \(error)")
            }
        }
    }

    // MARK: - Private Helpers

    private func fetchCumulativeSum(
        for quantityType: HKQuantityType,
        unit: HKUnit,
        startDate: Date,
        endDate: Date
    ) async throws -> Double {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let value = statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }

    private func fetchMostRecentHeartRate() async throws -> Double? {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchMostRecentQuantity(for: heartRateType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchRestingHeartRate() async throws -> Double? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchMostRecentQuantity(for: restingHRType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchWalkingHeartRateAverage() async throws -> Double? {
        guard let walkingHRType = HKQuantityType.quantityType(forIdentifier: .walkingHeartRateAverage) else {
            throw HealthKitError.typeNotAvailable
        }

        return try await fetchMostRecentQuantity(for: walkingHRType, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchMostRecentQuantity(for quantityType: HKQuantityType, unit: HKUnit) async throws -> Double? {
        guard let healthStore = healthStore else {
            throw HealthKitError.notAvailable
        }

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierEndDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: quantityType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }

            healthStore.execute(query)
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case typeNotAvailable
    case authorizationDenied

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device."
        case .typeNotAvailable:
            return "The requested health data type is not available."
        case .authorizationDenied:
            return "Health data access was denied."
        }
    }
}
