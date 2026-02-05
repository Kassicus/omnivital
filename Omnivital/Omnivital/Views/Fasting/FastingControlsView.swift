//
//  FastingControlsView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct FastingControlsView: View {
    let hasActiveFast: Bool
    let onStart: () -> Void
    let onComplete: () -> Void
    let onCancel: () -> Void

    var body: some View {
        if hasActiveFast {
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button(action: onComplete) {
                    Label("Complete", systemImage: "checkmark.circle")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        } else {
            Button(action: onStart) {
                Label("Start Fast", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }
}

#Preview("No Active Fast") {
    FastingControlsView(
        hasActiveFast: false,
        onStart: {},
        onComplete: {},
        onCancel: {}
    )
    .padding()
}

#Preview("Active Fast") {
    FastingControlsView(
        hasActiveFast: true,
        onStart: {},
        onComplete: {},
        onCancel: {}
    )
    .padding()
}
