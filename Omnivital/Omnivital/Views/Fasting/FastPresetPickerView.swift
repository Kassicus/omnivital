//
//  FastPresetPickerView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct FastPresetPickerView: View {
    @Binding var selectedPreset: FastPreset
    @Binding var customDurationHours: Double

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Fasting Duration")
                .font(.headline)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(FastPreset.allCases, id: \.self) { preset in
                    PresetButton(
                        preset: preset,
                        isSelected: selectedPreset == preset,
                        action: { selectedPreset = preset }
                    )
                }
            }

            if selectedPreset == .custom {
                VStack(spacing: 12) {
                    Text("\(Int(customDurationHours)) hours")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)

                    Slider(value: $customDurationHours, in: 1...24, step: 1)
                        .tint(.orange)

                    HStack {
                        Text("1h")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("24h")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
    }
}

struct PresetButton: View {
    let preset: FastPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(preset.displayName)
                    .font(.headline)
                    .fontWeight(.bold)

                if preset != .custom {
                    Text("\(Int(preset.hours))h fasting")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            #if os(iOS)
            .background(isSelected ? Color.orange : Color(uiColor: .secondarySystemGroupedBackground))
            #else
            .background(isSelected ? Color.orange : Color(nsColor: .controlBackgroundColor))
            #endif
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    FastPresetPickerView(
        selectedPreset: .constant(.sixteenEight),
        customDurationHours: .constant(16)
    )
    .padding()
}
