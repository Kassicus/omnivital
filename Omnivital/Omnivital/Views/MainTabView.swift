//
//  MainTabView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    let healthKitManager: HealthKitManager

    var body: some View {
        TabView {
            HealthDashboardView(healthKitManager: healthKitManager)
                .tabItem {
                    Label("Health", systemImage: "heart.fill")
                }

            FastingView()
                .tabItem {
                    Label("Fasting", systemImage: "fork.knife.circle")
                }
        }
    }
}

#Preview {
    MainTabView(healthKitManager: HealthKitManager())
        .modelContainer(for: Fast.self, inMemory: true)
}
