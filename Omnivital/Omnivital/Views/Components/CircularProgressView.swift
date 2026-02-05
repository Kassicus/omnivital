//
//  CircularProgressView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 8

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressView(progress: 0.75, color: .green)
            .frame(width: 100, height: 100)

        CircularProgressView(progress: 0.5, color: .red)
            .frame(width: 60, height: 60)

        CircularProgressView(progress: 1.0, color: .blue, lineWidth: 4)
            .frame(width: 40, height: 40)
    }
    .padding()
}
