//
//  FastingView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct FastingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: FastingViewModel?
    @State private var showCalendar = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    FastingContentView(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Fasting")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                if let viewModel = viewModel {
                    FastingCalendarView(viewModel: viewModel)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = FastingViewModel(modelContext: modelContext)
                    viewModel?.loadFasts()
                }
            }
        }
    }
}

struct FastingContentView: View {
    @Bindable var viewModel: FastingViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let activeFast = viewModel.activeFast {
                    FastingTimerView(fast: activeFast)
                        .padding(.top, 20)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text("Ready to Fast")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 20)

                    FastPresetPickerView(
                        selectedPreset: $viewModel.selectedPreset,
                        customDurationHours: $viewModel.customDurationHours
                    )
                    .padding(.horizontal)
                }

                FastingControlsView(
                    hasActiveFast: viewModel.activeFast != nil,
                    onStart: { viewModel.startFast() },
                    onComplete: { viewModel.completeFast() },
                    onCancel: { viewModel.cancelFast() }
                )
                .padding(.horizontal)

                if !viewModel.recentFasts.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Fasts")
                            .font(.headline)
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(viewModel.recentFasts.prefix(5), id: \.id) { fast in
                                FastRowView(fast: fast)
                                    .padding(.horizontal)
                                    .padding(.vertical, 8)

                                if fast.id != viewModel.recentFasts.prefix(5).last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                        #if os(iOS)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        #else
                        .background(Color(nsColor: .controlBackgroundColor))
                        #endif
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                }

                if let error = viewModel.error {
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding()
                }

                Spacer(minLength: 20)
            }
        }
        #if os(iOS)
        .background(Color(uiColor: .systemGroupedBackground))
        #else
        .background(Color(nsColor: .windowBackgroundColor))
        #endif
    }
}

#Preview {
    FastingView()
        .modelContainer(for: Fast.self, inMemory: true)
}
