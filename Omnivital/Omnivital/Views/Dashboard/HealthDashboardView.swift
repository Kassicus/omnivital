//
//  HealthDashboardView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI

struct HealthDashboardView: View {
    @State private var viewModel: HealthDashboardViewModel

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(healthKitManager: HealthKitManager) {
        self._viewModel = State(initialValue: HealthDashboardViewModel(healthKitManager: healthKitManager))
    }

    var body: some View {
        NavigationStack {
            Group {
                if !viewModel.isHealthKitAvailable {
                    HealthKitUnavailableView()
                } else {
                    switch viewModel.authorizationStatus {
                    case .notDetermined:
                        HealthPermissionView {
                            Task {
                                await viewModel.requestAuthorization()
                            }
                        }
                    case .denied:
                        PermissionDeniedView()
                    case .authorized:
                        dashboardContent
                    case .unavailable:
                        HealthKitUnavailableView()
                    }
                }
            }
            .navigationTitle("Health")
            .task {
                await viewModel.checkAuthorizationAndLoad()
            }
        }
    }

    @ViewBuilder
    private var dashboardContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary section
                HealthSummaryView(
                    metrics: viewModel.metrics,
                    selectedDate: viewModel.selectedDate,
                    onDateChange: { date in
                        viewModel.selectDate(date)
                    }
                )

                // Metrics grid
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.metrics) { metric in
                        MetricCardView(metric: metric)
                    }
                }
                .padding(.horizontal)

                // Error display
                if let error = viewModel.error {
                    ErrorBanner(message: error.localizedDescription)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .refreshable {
            await viewModel.refresh()
        }
        .overlay {
            if viewModel.isLoading && viewModel.metrics.isEmpty {
                ProgressView("Loading health data...")
            }
        }
    }
}

struct HealthKitUnavailableView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "iphone.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                Text("HealthKit Unavailable")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("HealthKit is not available on this device. Please use a physical iPhone to access health data.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        #if os(iOS)
        .background(Color(uiColor: .systemBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HealthDashboardView(healthKitManager: HealthKitManager())
}
