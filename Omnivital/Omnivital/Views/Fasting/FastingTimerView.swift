//
//  FastingTimerView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import Combine

struct FastingTimerView: View {
    let fast: Fast
    @State private var currentTime = Date()
    @State private var showPhaseDetail = false
    @State private var selectedPhaseForDetail: FastingPhase?

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var elapsedSeconds: TimeInterval {
        currentTime.timeIntervalSince(fast.startTime)
    }

    private var elapsedHours: Double {
        elapsedSeconds / 3600
    }

    private var progress: Double {
        let targetSeconds = fast.targetDurationHours * 3600
        guard targetSeconds > 0 else { return 0 }
        return min(elapsedSeconds / targetSeconds, 1.0)
    }

    private var percentComplete: Int {
        Int(progress * 100)
    }

    private var remainingSeconds: TimeInterval {
        let targetSeconds = fast.targetDurationHours * 3600
        return max(targetSeconds - elapsedSeconds, 0)
    }

    private var isComplete: Bool {
        elapsedSeconds >= fast.targetDurationHours * 3600
    }

    private var currentPhase: FastingPhase {
        FastingPhase.phase(forElapsedHours: elapsedHours)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Progress ring with percentage
            ZStack {
                CircularProgressView(
                    progress: progress,
                    color: currentPhase.color,
                    lineWidth: 14
                )
                .frame(width: 200, height: 200)

                VStack(spacing: 4) {
                    Text("\(percentComplete)%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(currentPhase.color)

                    Text(formatTime(elapsedSeconds))
                        .font(.system(size: 18, weight: .medium, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
            }

            // Current phase card
            Button {
                showPhaseDetail = true
            } label: {
                CurrentPhaseCard(phase: currentPhase)
            }
            .buttonStyle(.plain)

            // Stats row
            HStack(spacing: 24) {
                StatItem(
                    icon: "target",
                    label: "Target",
                    value: formatHours(fast.targetDurationHours)
                )

                if isComplete {
                    StatItem(
                        icon: "checkmark.circle.fill",
                        label: "Status",
                        value: "Complete",
                        valueColor: .green
                    )
                } else {
                    StatItem(
                        icon: "hourglass",
                        label: "Remaining",
                        value: formatTimeShort(remainingSeconds)
                    )
                }

                StatItem(
                    icon: "clock",
                    label: "Started",
                    value: fast.startTime.formatted(date: .omitted, time: .shortened)
                )
            }

            // Phase timeline (tap any phase to learn more)
            FastingPhaseTimeline(
                elapsedHours: elapsedHours,
                targetHours: fast.targetDurationHours,
                onPhaseTap: { phase in
                    selectedPhaseForDetail = phase
                }
            )
            .padding(.top, 8)
        }
        .onReceive(timer) { time in
            currentTime = time
        }
        .sheet(isPresented: $showPhaseDetail) {
            FastingPhaseDetailSheet(currentPhase: currentPhase, elapsedHours: elapsedHours)
        }
        .sheet(item: $selectedPhaseForDetail) { phase in
            SinglePhaseDetailSheet(phase: phase, elapsedHours: elapsedHours)
        }
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, secs)
    }

    private func formatTimeShort(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatHours(_ hours: Double) -> String {
        if hours == floor(hours) {
            return "\(Int(hours))h"
        } else {
            return String(format: "%.1fh", hours)
        }
    }
}

struct CurrentPhaseCard: View {
    let phase: FastingPhase

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: phase.icon)
                .font(.title2)
                .foregroundStyle(phase.color)
                .frame(width: 40, height: 40)
                .background(phase.color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(phase.shortDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let icon: String
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
}

struct FastingPhaseTimeline: View {
    let elapsedHours: Double
    let targetHours: Double
    var onPhaseTap: ((FastingPhase) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Fasting Phases")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Tap to learn more")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            HStack(spacing: 4) {
                ForEach(FastingPhase.allCases, id: \.self) { phase in
                    PhaseSegment(
                        phase: phase,
                        isUnlocked: elapsedHours >= phase.startHour,
                        isActive: FastingPhase.phase(forElapsedHours: elapsedHours) == phase
                    )
                    .onTapGesture {
                        onPhaseTap?(phase)
                    }
                }
            }

            HStack {
                Text("0h")
                Spacer()
                Text("4h")
                Spacer()
                Text("8h")
                Spacer()
                Text("12h")
                Spacer()
                Text("18h")
                Spacer()
                Text("24h+")
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
    }
}

struct PhaseSegment: View {
    let phase: FastingPhase
    let isUnlocked: Bool
    let isActive: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(isUnlocked ? phase.color : phase.color.opacity(0.2))
            .frame(height: isActive ? 12 : 8)
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(phase.color, lineWidth: 2)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isActive)
    }
}

struct FastingPhaseDetailSheet: View {
    let currentPhase: FastingPhase
    let elapsedHours: Double
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Current phase header
                    VStack(spacing: 12) {
                        Image(systemName: currentPhase.icon)
                            .font(.system(size: 50))
                            .foregroundStyle(currentPhase.color)

                        Text(currentPhase.displayName)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(currentPhase.detailedDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)

                    // Current benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Benefits")
                            .font(.headline)

                        ForEach(currentPhase.benefits, id: \.self) { benefit in
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(currentPhase.color)
                                Text(benefit)
                                    .font(.subheadline)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    #if os(iOS)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    #else
                    .background(Color(nsColor: .controlBackgroundColor))
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // All phases
                    VStack(alignment: .leading, spacing: 12) {
                        Text("All Fasting Phases")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(FastingPhase.allCases, id: \.self) { phase in
                            PhaseRow(
                                phase: phase,
                                isUnlocked: elapsedHours >= phase.startHour,
                                isCurrent: phase == currentPhase
                            )
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.bottom, 32)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .navigationTitle("Fasting Phases")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct PhaseRow: View {
    let phase: FastingPhase
    let isUnlocked: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? phase.color : Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)

                Image(systemName: phase.icon)
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? .white : .gray)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(phase.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)

                    if isCurrent {
                        Text("CURRENT")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(phase.color)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }

                Text("\(Int(phase.startHour))+ hours")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding()
        #if os(iOS)
        .background(isCurrent ? phase.color.opacity(0.1) : Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(isCurrent ? phase.color.opacity(0.1) : Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay {
            if isCurrent {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(phase.color, lineWidth: 2)
            }
        }
        .padding(.horizontal)
    }
}

struct ProgressToPhaseCard: View {
    let phase: FastingPhase
    let elapsedHours: Double

    private var progressToPhase: Double {
        elapsedHours / phase.startHour
    }

    private var hoursRemaining: Double {
        phase.startHour - elapsedHours
    }

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 12)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(phase.color)
                            .frame(width: max(0, CGFloat(progressToPhase) * geometry.size.width), height: 12)
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("\(String(format: "%.1f", elapsedHours))h elapsed")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text("\(Int(phase.startHour))h to unlock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundStyle(phase.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(String(format: "%.1f", hoursRemaining)) hours to go")
                        .font(.headline)

                    Text("Keep fasting to unlock this phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        #else
        .background(Color(nsColor: .controlBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SinglePhaseDetailSheet: View {
    let phase: FastingPhase
    let elapsedHours: Double
    @Environment(\.dismiss) private var dismiss

    private var hoursInPhase: Double {
        let nextPhaseStart = nextPhaseStartHour
        if elapsedHours < phase.startHour {
            return 0
        } else if elapsedHours >= nextPhaseStart {
            return nextPhaseStart - phase.startHour
        } else {
            return elapsedHours - phase.startHour
        }
    }

    private var nextPhaseStartHour: Double {
        let allPhases = FastingPhase.allCases
        guard let currentIndex = allPhases.firstIndex(of: phase),
              currentIndex + 1 < allPhases.count else {
            return 48 // Arbitrary high number for deep ketosis
        }
        return allPhases[currentIndex + 1].startHour
    }

    private var isCurrentPhase: Bool {
        FastingPhase.phase(forElapsedHours: elapsedHours) == phase
    }

    private var hasReached: Bool {
        elapsedHours >= phase.startHour
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Phase header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(hasReached ? phase.color : Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)

                            Image(systemName: phase.icon)
                                .font(.system(size: 44))
                                .foregroundStyle(hasReached ? .white : .gray)
                        }

                        VStack(spacing: 8) {
                            Text(phase.displayName)
                                .font(.title)
                                .fontWeight(.bold)

                            HStack(spacing: 8) {
                                Text("Starts at \(Int(phase.startHour)) hours")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)

                                if isCurrentPhase {
                                    Text("ACTIVE")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(phase.color)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                } else if hasReached {
                                    Text("COMPLETED")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    .padding(.top)

                    // Time spent in phase
                    if hasReached {
                        VStack(spacing: 8) {
                            Text(String(format: "%.1f hours", hoursInPhase))
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(phase.color)

                            Text("spent in this phase")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        #if os(iOS)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        #else
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What's Happening")
                            .font(.headline)

                        Text(phase.detailedDescription)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    #if os(iOS)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    #else
                    .background(Color(nsColor: .controlBackgroundColor))
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Benefits
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Benefits")
                            .font(.headline)

                        ForEach(phase.benefits, id: \.self) { benefit in
                            HStack(spacing: 12) {
                                Image(systemName: hasReached ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(hasReached ? phase.color : .gray)
                                Text(benefit)
                                    .font(.subheadline)
                                    .foregroundStyle(hasReached ? .primary : .secondary)
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    #if os(iOS)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    #else
                    .background(Color(nsColor: .controlBackgroundColor))
                    #endif
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)

                    // Progress to this phase
                    if !hasReached {
                        ProgressToPhaseCard(
                            phase: phase,
                            elapsedHours: elapsedHours
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 32)
            }
            #if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
            #else
            .background(Color(nsColor: .windowBackgroundColor))
            #endif
            .navigationTitle(phase.displayName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview("Active Fast - 8 hours") {
    FastingTimerView(fast: Fast(
        startTime: Date().addingTimeInterval(-3600 * 8),
        targetDurationHours: 16,
        preset: .sixteenEight
    ))
    .padding()
}

#Preview("Active Fast - 14 hours") {
    FastingTimerView(fast: Fast(
        startTime: Date().addingTimeInterval(-3600 * 14),
        targetDurationHours: 16,
        preset: .sixteenEight
    ))
    .padding()
}

#Preview("Phase Detail Sheet") {
    FastingPhaseDetailSheet(currentPhase: .fatBurning, elapsedHours: 14)
}

#Preview("Single Phase - Reached") {
    SinglePhaseDetailSheet(phase: .fastingState, elapsedHours: 10)
}

#Preview("Single Phase - Not Reached") {
    SinglePhaseDetailSheet(phase: .ketosis, elapsedHours: 10)
}
