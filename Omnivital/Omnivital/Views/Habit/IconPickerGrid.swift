//
//  IconPickerGrid.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct IconPickerGrid: View {
    @Binding var selectedIcon: String
    let accentColor: Color

    static let icons = [
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "leaf.fill", "book.fill", "figure.walk", "figure.run",
        "drop.fill", "moon.fill", "sun.max.fill", "brain.head.profile",
        "pill.fill", "cross.fill", "bed.double.fill", "cup.and.saucer.fill",
        "pencil", "music.note", "paintbrush.fill", "camera.fill",
        "graduationcap.fill", "dumbbell.fill"
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Self.icons, id: \.self) { icon in
                Button {
                    selectedIcon = icon
                } label: {
                    Image(systemName: icon)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(
                            selectedIcon == icon
                                ? accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .foregroundStyle(selectedIcon == icon ? accentColor : .secondary)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedIcon == icon ? accentColor : .clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
