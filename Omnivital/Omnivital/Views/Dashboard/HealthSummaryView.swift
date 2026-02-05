//
//  HealthSummaryView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HealthSummaryView: View {
    let metrics: [HealthMetric]
    let selectedDate: Date
    let onDateChange: (Date) -> Void

    @State private var showDatePicker = false

    private var stepsMetric: HealthMetric? {
        metrics.first { $0.type == .steps }
    }

    private var caloriesMetric: HealthMetric? {
        metrics.first { $0.type == .activeCalories }
    }

    private var standMetric: HealthMetric? {
        metrics.first { $0.type == .standHours }
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        VStack(spacing: 16) {
            // Date selector
            HStack {
                Button(action: { showDatePicker = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                        Text(dateText)
                            .fontWeight(.semibold)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundStyle(.primary)
                }

                Spacer()

                if !isToday {
                    Button("Today") {
                        onDateChange(Date())
                    }
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)

            // Activity rings summary
            HStack(spacing: 24) {
                if let steps = stepsMetric {
                    RingSummaryItem(
                        title: "Steps",
                        value: steps.formattedValue,
                        progress: steps.progress ?? 0,
                        color: steps.type.color
                    )
                }

                if let calories = caloriesMetric {
                    RingSummaryItem(
                        title: "Calories",
                        value: calories.formattedValue,
                        progress: calories.progress ?? 0,
                        color: calories.type.color
                    )
                }

                if let stand = standMetric {
                    RingSummaryItem(
                        title: "Stand",
                        value: "\(Int(stand.value))h",
                        progress: stand.progress ?? 0,
                        color: stand.type.color
                    )
                }
            }
            .padding()
            #if os(iOS)
            .background(Color(uiColor: .systemBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding(.horizontal)
        }
        .sheet(isPresented: $showDatePicker) {
            DatePickerSheet(
                selectedDate: selectedDate,
                onSelect: { date in
                    onDateChange(date)
                    showDatePicker = false
                }
            )
            .presentationDetents([.medium])
        }
    }

    private var dateText: String {
        if isToday {
            return "Today"
        } else if Calendar.current.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: selectedDate)
        }
    }
}

struct RingSummaryItem: View {
    let title: String
    let value: String
    let progress: Double
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                CircularProgressView(progress: progress, color: color, lineWidth: 6)
                    .frame(width: 50, height: 50)

                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DatePickerSheet: View {
    let selectedDate: Date
    let onSelect: (Date) -> Void

    @State private var pickedDate: Date

    init(selectedDate: Date, onSelect: @escaping (Date) -> Void) {
        self.selectedDate = selectedDate
        self.onSelect = onSelect
        self._pickedDate = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            DatePicker(
                "Select Date",
                selection: $pickedDate,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Date")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        onSelect(pickedDate)
                    }
                }
            }
        }
    }
}

#Preview {
    HealthSummaryView(
        metrics: [
            HealthMetric(type: .steps, value: 7543, date: Date()),
            HealthMetric(type: .activeCalories, value: 320, date: Date()),
            HealthMetric(type: .standHours, value: 8, date: Date())
        ],
        selectedDate: Date(),
        onDateChange: { _ in }
    )
    .padding(.vertical)
    #if os(iOS)
    .background(Color(uiColor: .systemGroupedBackground))
    #else
    .background(Color(nsColor: .windowBackgroundColor))
    #endif
}
