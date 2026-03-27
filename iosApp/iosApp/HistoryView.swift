import SwiftUI
import SharedTts

struct HistoryView: View {
    @ObservedObject var vm: TtsViewModelWrapper
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if vm.history.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "clock")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No History")
                            .font(.title3.bold())
                        Text("Spoken texts will appear here.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    List {
                        ForEach(vm.history, id: \.id) { item in
                            HistoryRowView(item: item) {
                                vm.respeak(item)
                                dismiss()
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { vm.deleteItem(vm.history[$0]) }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !vm.history.isEmpty {
                        Button(role: .destructive) {
                            vm.clearHistory()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

private struct HistoryRowView: View {
    let item: TtsHistoryItem
    let onRespeak: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.text)
                .font(.body)
                .lineLimit(2)
            HStack(spacing: 12) {
                Label(String(format: "Pitch %.1f", item.pitch), systemImage: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Label(String(format: "Speed %.1f", item.rate), systemImage: "speedometer")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !item.languageTag.isEmpty {
                    Label(item.languageTag, systemImage: "globe")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(Date(timeIntervalSince1970: TimeInterval(item.timestamp) / 1000), style: .relative)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture { onRespeak() }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                onRespeak()
            } label: {
                Label("Speak", systemImage: "play.fill")
            }
            .tint(.accentColor)
        }
    }
}
