//
//  PlateCalculatorView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct PlateCalculatorView: View {
    let totalWeight: Double
    var barbellWeight: Double = 45

    private var plateBreakdown: [(weight: Double, count: Int, color: Color)] {
        PlateCalculator.calculatePlates(
            totalWeight: totalWeight,
            barbellWeight: barbellWeight
        )
    }

    private var weightPerSide: Double {
        max(0, (totalWeight - barbellWeight) / 2)
    }

    private var isJustBarbell: Bool {
        totalWeight <= barbellWeight
    }

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "scalemass.fill")
                    .foregroundStyle(.secondary)
                Text("Plate Setup")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(barbellWeight)) lb bar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isJustBarbell {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Just the barbell — no plates needed")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            } else {
                // Visual barbell representation
                BarbellVisualization(plates: plateBreakdown)

                // Plate list
                HStack {
                    Text("Per side:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    ForEach(plateBreakdown, id: \.weight) { plate in
                        if plate.count > 0 {
                            PlateChip(weight: plate.weight, count: plate.count, color: plate.color)
                        }
                    }
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
    }
}

struct BarbellVisualization: View {
    let plates: [(weight: Double, count: Int, color: Color)]

    var body: some View {
        HStack(spacing: 0) {
            // Left collar
            Rectangle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 12)

            // Left plates (reversed order - heaviest closest to center)
            HStack(spacing: 1) {
                ForEach(plates.reversed(), id: \.weight) { plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        PlateBar(weight: plate.weight, color: plate.color)
                    }
                }
            }

            // Barbell center
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 60, height: 8)

            // Right plates
            HStack(spacing: 1) {
                ForEach(plates, id: \.weight) { plate in
                    ForEach(0..<plate.count, id: \.self) { _ in
                        PlateBar(weight: plate.weight, color: plate.color)
                    }
                }
            }

            // Right collar
            Rectangle()
                .fill(Color.gray.opacity(0.6))
                .frame(width: 8, height: 12)
        }
        .frame(height: 50)
    }
}

struct PlateBar: View {
    let weight: Double
    let color: Color

    private var height: CGFloat {
        switch weight {
        case 45: return 50
        case 35: return 44
        case 25: return 38
        case 10: return 32
        case 5: return 26
        case 2.5: return 20
        default: return 30
        }
    }

    private var width: CGFloat {
        switch weight {
        case 45: return 10
        case 35: return 9
        case 25: return 8
        case 10: return 6
        case 5: return 5
        case 2.5: return 4
        default: return 6
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: width, height: height)
    }
}

struct PlateChip: View {
    let weight: Double
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(weight == 2.5 ? "2.5" : "\(Int(weight))")
                .font(.caption2)
                .fontWeight(.medium)

            Text("×\(count)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
    }
}

struct PlateCalculator {
    static let standardPlates: [(weight: Double, color: Color)] = [
        (45, .red),
        (35, .yellow),
        (25, .green),
        (10, .white),
        (5, .blue),
        (2.5, .gray)
    ]

    static func calculatePlates(
        totalWeight: Double,
        barbellWeight: Double = 45
    ) -> [(weight: Double, count: Int, color: Color)] {
        var remaining = (totalWeight - barbellWeight) / 2  // Weight per side

        if remaining <= 0 {
            return standardPlates.map { ($0.weight, 0, $0.color) }
        }

        var result: [(weight: Double, count: Int, color: Color)] = []

        for plate in standardPlates {
            let count = Int(remaining / plate.weight)
            result.append((plate.weight, count, plate.color))
            remaining -= Double(count) * plate.weight
        }

        return result
    }
}

// Compact inline version for the set view
struct PlateCalculatorInline: View {
    let totalWeight: Double
    var barbellWeight: Double = 45

    private var plateBreakdown: [(weight: Double, count: Int, color: Color)] {
        PlateCalculator.calculatePlates(
            totalWeight: totalWeight,
            barbellWeight: barbellWeight
        )
    }

    private var hasPlates: Bool {
        plateBreakdown.contains { $0.count > 0 }
    }

    var body: some View {
        if hasPlates {
            HStack(spacing: 4) {
                Image(systemName: "circle.dotted")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                ForEach(plateBreakdown, id: \.weight) { plate in
                    if plate.count > 0 {
                        Text("\(plate.count)×\(plate.weight == 2.5 ? "2.5" : "\(Int(plate.weight))")")
                            .font(.caption2)
                            .foregroundStyle(plate.color)
                    }
                }

                Text("per side")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        } else {
            Text("Empty bar")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview("135 lbs") {
    PlateCalculatorView(totalWeight: 135)
        .padding()
}

#Preview("225 lbs") {
    PlateCalculatorView(totalWeight: 225)
        .padding()
}

#Preview("315 lbs") {
    PlateCalculatorView(totalWeight: 315)
        .padding()
}

#Preview("45 lbs (just bar)") {
    PlateCalculatorView(totalWeight: 45)
        .padding()
}

#Preview("Inline") {
    VStack {
        PlateCalculatorInline(totalWeight: 135)
        PlateCalculatorInline(totalWeight: 225)
        PlateCalculatorInline(totalWeight: 45)
    }
    .padding()
}
