//
//  MetricCardView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct MetricCardView: View {
    let metric: HealthMetric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack {
                Image(systemName: metric.type.icon)
                    .font(.title3)
                    .foregroundStyle(metric.type.color)

                Spacer()

                if let progress = metric.progress {
                    CircularProgressView(
                        progress: progress,
                        color: metric.type.color,
                        lineWidth: 4
                    )
                    .frame(width: 28, height: 28)
                }
            }

            Spacer()

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(metric.formattedValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(metric.type.unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Label
            Text(metric.type.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        MetricCardView(metric: HealthMetric(
            type: .steps,
            value: 7543,
            date: Date()
        ))

        MetricCardView(metric: HealthMetric(
            type: .heartRate,
            value: 72,
            date: Date()
        ))

        MetricCardView(metric: HealthMetric(
            type: .sleep,
            value: 7.5,
            date: Date()
        ))
    }
    .padding()
    #if os(iOS)
    .background(Color(uiColor: .systemGroupedBackground))
    #else
    .background(Color(nsColor: .windowBackgroundColor))
    #endif
}
