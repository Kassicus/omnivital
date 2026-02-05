//
//  FastRowView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct FastRowView: View {
    let fast: Fast

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(fast.startTime, style: .time)
                        .font(.headline)

                    if let endTime = fast.endTime {
                        Text("→")
                            .foregroundStyle(.secondary)
                        Text(endTime, style: .time)
                            .font(.headline)
                    }
                }

                HStack(spacing: 8) {
                    Text(fast.durationFormatted)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    if let preset = fast.preset {
                        Text(preset.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            StatusBadge(state: fast.state)
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch fast.state {
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

struct StatusBadge: View {
    let state: FastState

    var body: some View {
        Text(state.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }

    private var backgroundColor: Color {
        switch state {
        case .active: return .blue.opacity(0.2)
        case .completed: return .green.opacity(0.2)
        case .cancelled: return .red.opacity(0.2)
        }
    }

    private var foregroundColor: Color {
        switch state {
        case .active: return .blue
        case .completed: return .green
        case .cancelled: return .red
        }
    }
}

#Preview {
    List {
        FastRowView(fast: Fast(
            startTime: Date().addingTimeInterval(-3600 * 18),
            endTime: Date().addingTimeInterval(-3600 * 2),
            targetDurationHours: 16,
            state: .completed,
            preset: .sixteenEight
        ))

        FastRowView(fast: Fast(
            startTime: Date().addingTimeInterval(-3600 * 8),
            targetDurationHours: 16,
            state: .active,
            preset: .sixteenEight
        ))

        FastRowView(fast: Fast(
            startTime: Date().addingTimeInterval(-3600 * 12),
            endTime: Date().addingTimeInterval(-3600 * 6),
            targetDurationHours: 18,
            state: .cancelled,
            preset: .eighteenSix
        ))
    }
}
