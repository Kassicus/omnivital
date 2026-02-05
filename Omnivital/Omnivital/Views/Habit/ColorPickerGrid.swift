//
//  ColorPickerGrid.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct ColorPickerGrid: View {
    @Binding var selectedColor: HabitColor

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(HabitColor.allCases) { habitColor in
                Button {
                    selectedColor = habitColor
                } label: {
                    Circle()
                        .fill(habitColor.color)
                        .frame(width: 36, height: 36)
                        .overlay {
                            if selectedColor == habitColor {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .overlay {
                            if selectedColor == habitColor {
                                Circle()
                                    .stroke(habitColor.color, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
