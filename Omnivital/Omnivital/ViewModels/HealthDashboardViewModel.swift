//
//  HealthDashboardViewModel.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import Foundation

@Observable
@MainActor
final class HealthDashboardViewModel {
    let healthKitManager: HealthKitManager

    var metrics: [HealthMetric] = []
    var heartRateData: HeartRateData?
    var sleepData: SleepData?
    var selectedDate: Date = Date()
    var isLoading: Bool = false
    var error: Error?

    var authorizationStatus: HealthKitAuthorizationStatus {
        healthKitManager.authorizationStatus
    }

    var isHealthKitAvailable: Bool {
        healthKitManager.isHealthKitAvailable
    }

    init(healthKitManager: HealthKitManager) {
        self.healthKitManager = healthKitManager
    }

    func checkAuthorizationAndLoad() async {
        healthKitManager.checkAuthorizationStatus()

        if authorizationStatus == .authorized {
            await loadAllMetrics()
        }
    }

    func requestAuthorization() async {
        do {
            try await healthKitManager.requestAuthorization()
            await loadAllMetrics()
        } catch {
            self.error = error
        }
    }

    func loadAllMetrics() async {
        isLoading = true
        error = nil

        do {
            async let steps = healthKitManager.fetchSteps(for: selectedDate)
            async let calories = healthKitManager.fetchActiveCalories(for: selectedDate)
            async let distance = healthKitManager.fetchDistance(for: selectedDate)
            async let standHours = healthKitManager.fetchStandHours(for: selectedDate)
            async let heartRate = healthKitManager.fetchHeartRate()
            async let sleep = healthKitManager.fetchSleepAnalysis(for: selectedDate)

            let stepsValue = try await steps
            let caloriesValue = try await calories
            let distanceValue = try await distance
            let standHoursValue = try await standHours
            let heartRateValue = try await heartRate
            let sleepValue = try await sleep

            self.heartRateData = heartRateValue
            self.sleepData = sleepValue

            var newMetrics: [HealthMetric] = []

            newMetrics.append(HealthMetric(
                type: .steps,
                value: stepsValue,
                date: selectedDate
            ))

            newMetrics.append(HealthMetric(
                type: .activeCalories,
                value: caloriesValue,
                date: selectedDate
            ))

            if let currentHR = heartRateValue.current {
                newMetrics.append(HealthMetric(
                    type: .heartRate,
                    value: currentHR,
                    date: selectedDate
                ))
            }

            if let restingHR = heartRateValue.resting {
                newMetrics.append(HealthMetric(
                    type: .restingHeartRate,
                    value: restingHR,
                    date: selectedDate
                ))
            }

            if let walkingHR = heartRateValue.walkingAverage {
                newMetrics.append(HealthMetric(
                    type: .walkingHeartRateAverage,
                    value: walkingHR,
                    date: selectedDate
                ))
            }

            newMetrics.append(HealthMetric(
                type: .distance,
                value: distanceValue,
                date: selectedDate
            ))

            newMetrics.append(HealthMetric(
                type: .sleep,
                value: sleepValue.totalSleepHours,
                date: selectedDate
            ))

            newMetrics.append(HealthMetric(
                type: .standHours,
                value: standHoursValue,
                date: selectedDate
            ))

            self.metrics = newMetrics
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func refresh() async {
        await loadAllMetrics()
    }

    func selectDate(_ date: Date) {
        selectedDate = date
        Task {
            await loadAllMetrics()
        }
    }
}
