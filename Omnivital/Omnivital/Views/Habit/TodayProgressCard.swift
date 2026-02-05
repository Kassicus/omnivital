//
//  TodayProgressCard.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct TodayProgressCard: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                CircularProgressView(progress: progress, color: .green, lineWidth: 10)
                    .frame(width: 120, height: 120)

                VStack(spacing: 2) {
                    if progress >= 1.0 {
                        Image(systemName: "checkmark")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                    } else {
                        Text("\(completedCount)/\(totalCount)")
                            .font(.title2.bold())
                        Text("today")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if progress >= 1.0 {
                Text("All habits complete!")
                    .font(.subheadline.bold())
                    .foregroundStyle(.green)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
