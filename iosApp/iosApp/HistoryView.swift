import SwiftUI
import UIKit
import SharedTts

// MARK: - UIKit scroll-position bridge

/// Invisible UIView embedded as the first List row.
/// It walks up the superview chain to find the UIScrollView (UICollectionView / UITableView)
/// that backs the List, then:
///   • immediately restores contentOffset (no visible jump because it runs before layout settles)
///   • observes future contentOffset changes via KVO and reports them via a closure
private final class ScrollTrackerView: UIView {
    var onOffsetChange: ((CGFloat) -> Void)?
    private var observation: NSKeyValueObservation?

    func attach(to scrollView: UIScrollView, restoreOffset: CGFloat) {
        // Restore before the first frame is painted
        if restoreOffset > 0 {
            scrollView.setContentOffset(CGPoint(x: 0, y: restoreOffset), animated: false)
        }
        // Track future changes
        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
            let y = sv.contentOffset.y
            guard y >= 0 else { return }   // ignore rubber-band negative values
            DispatchQueue.main.async { self?.onOffsetChange?(y) }
        }
    }

    deinit { observation?.invalidate() }
}

private struct ScrollPositionBridge: UIViewRepresentable {
    let restoreOffset: CGFloat
    let onOffsetChange: (CGFloat) -> Void

    func makeUIView(context: Context) -> ScrollTrackerView {
        let view = ScrollTrackerView()
        view.isHidden = true
        view.onOffsetChange = onOffsetChange
        // Defer one run-loop tick so the cell is fully inserted into the hierarchy
        DispatchQueue.main.async {
            var ancestor = view.superview
            while let node = ancestor {
                if let sv = node as? UIScrollView {
                    view.attach(to: sv, restoreOffset: restoreOffset)
                    break
                }
                ancestor = node.superview
            }
        }
        return view
    }

    func updateUIView(_ uiView: ScrollTrackerView, context: Context) {
        uiView.onOffsetChange = onOffsetChange
    }
}

// MARK: - HistoryView

struct HistoryView: View {
    @ObservedObject var vm: TtsViewModelWrapper
    @Environment(\.dismiss) private var dismiss

    /// Decided once at init so the restore happens on the very first render.
    private let shouldRestore: Bool
    @State private var showClearConfirm = false

    init(vm: TtsViewModelWrapper) {
        self.vm = vm
        if let savedTime = vm.savedHistoryScrollTime {
            self.shouldRestore = Date().timeIntervalSince(savedTime) < 60
        } else {
            self.shouldRestore = false
        }
    }

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
                        // ── Invisible bridge row ──────────────────────────────────────
                        // Must live inside the List so its superview chain includes
                        // the UICollectionView / UITableView scroll view.
                        ScrollPositionBridge(
                            restoreOffset: shouldRestore ? vm.savedHistoryScrollOffset : 0,
                            onOffsetChange: { vm.savedHistoryScrollOffset = $0 }
                        )
                        .frame(width: 0, height: 0)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        // ─────────────────────────────────────────────────────────────

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
                    .onDisappear {
                        // Record the moment the sheet is closed for the 60-second check
                        vm.savedHistoryScrollTime = Date()
                    }
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
                            showClearConfirm = true
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    }
                }
            }
            .confirmationDialog("Clear all history?", isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear All", role: .destructive) { vm.clearHistory() }
                Button("Cancel", role: .cancel) { }
            }
        }
    }
}

// MARK: - HistoryRowView

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
