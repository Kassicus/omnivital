//
//  HabitView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct HabitView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: HabitViewModel?
    @State private var showCalendar = false
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    HabitDashboardView(viewModel: viewModel)
                } else {
                    ProgressView("Loading...")
                }
            }
            .navigationTitle("Habits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 12) {
                        Button {
                            showCalendar = true
                        } label: {
                            Image(systemName: "calendar")
                        }

                        Button {
                            showEditor = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCalendar) {
                if let viewModel = viewModel {
                    HabitCalendarView(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showEditor) {
                if let viewModel = viewModel {
                    HabitEditorView(viewModel: viewModel)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = HabitViewModel(modelContext: modelContext)
                    viewModel?.loadHabits()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
    }
}

#Preview {
    HabitView()
        .modelContainer(for: [Habit.self, HabitCompletion.self], inMemory: true)
}
