//
//  FastingCalendarView.swift
//  Omnivital
//
//  Created by Kason Suchow on 2/5/26.
//

import SwiftUI
import SwiftData

struct FastingCalendarView: View {
    @Bindable var viewModel: FastingViewModel
    @State private var selectedFast: Fast?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { viewModel.selectedDate },
                        set: { viewModel.selectDate($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()

                Divider()

                if viewModel.fastsForSelectedDate.isEmpty {
                    ContentUnavailableView {
                        Label("No Fasts", systemImage: "fork.knife.circle")
                    } description: {
                        Text("No fasts recorded on this date")
                    }
                } else {
                    List {
                        ForEach(viewModel.fastsForSelectedDate, id: \.id) { fast in
                            FastRowView(fast: fast)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedFast = fast
                                }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let fast = viewModel.fastsForSelectedDate[index]
                                viewModel.deleteFast(fast)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Fasting History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedFast) { fast in
                FastDetailView(
                    fast: fast,
                    onSave: { startTime, endTime, notes in
                        viewModel.updateFast(fast, startTime: startTime, endTime: endTime, notes: notes)
                    },
                    onDelete: {
                        viewModel.deleteFast(fast)
                    }
                )
            }
        }
    }
}

#Preview {
    FastingCalendarView(viewModel: {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Fast.self, configurations: config)
        return FastingViewModel(modelContext: container.mainContext)
    }())
}
