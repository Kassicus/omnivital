//
//  WeekdayPickerView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct WeekdayPickerView: View {
    @Binding var selectedDays: Set<Weekday>

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Weekday.allCases) { day in
                Button {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                } label: {
                    Text(day.shortName)
                        .font(.subheadline.bold())
                        .frame(width: 36, height: 36)
                        .foregroundStyle(selectedDays.contains(day) ? .white : .primary)
                        .background(
                            selectedDays.contains(day) ? Color.accentColor : Color.clear
                        )
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(selectedDays.contains(day) ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
