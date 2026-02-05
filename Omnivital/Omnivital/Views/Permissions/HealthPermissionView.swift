//
//  HealthPermissionView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HealthPermissionView: View {
    let onRequestPermission: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            Image(systemName: "heart.text.square.fill")
                .font(.system(size: 80))
                .foregroundStyle(.pink.gradient)

            // Title and description
            VStack(spacing: 12) {
                Text("Health Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Omnivital needs access to your health data to display your daily metrics, including steps, calories, heart rate, and more.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Features list
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "figure.walk",
                    color: .green,
                    title: "Activity Tracking",
                    description: "Steps, distance, and calories"
                )

                FeatureRow(
                    icon: "heart.fill",
                    color: .pink,
                    title: "Heart Rate",
                    description: "Current, resting, and walking average"
                )

                FeatureRow(
                    icon: "bed.double.fill",
                    color: .indigo,
                    title: "Sleep Analysis",
                    description: "Sleep duration and stages"
                )
            }
            .padding(.horizontal, 32)

            Spacer()

            // Permission button
            Button(action: onRequestPermission) {
                Text("Allow Health Access")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.pink.gradient)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)

            Text("Your data stays on your device and is never shared.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
                .frame(height: 20)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    HealthPermissionView(onRequestPermission: {})
}
