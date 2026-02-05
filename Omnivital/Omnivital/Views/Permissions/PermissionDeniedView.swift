//
//  PermissionDeniedView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct PermissionDeniedView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.slash.fill")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("Health Access Denied")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Omnivital needs access to your health data to display your metrics. Please enable Health access in Settings.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button(action: openSettings) {
                HStack {
                    Image(systemName: "gear")
                    Text("Open Settings")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
                .padding(.horizontal, 24)
                .background(.blue.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Spacer()
        }
    }

    private func openSettings() {
        #if os(iOS)
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
        #elseif os(macOS)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Health") {
            openURL(url)
        }
        #endif
    }
}

#Preview {
    PermissionDeniedView()
}
