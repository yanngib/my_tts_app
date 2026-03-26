import Foundation
import Combine
import SharedTts

/// ObservableObject wrapper that bridges KMP TtsService and IosTtsRepository to SwiftUI.
/// Uses a polling timer to read KMP StateFlow values (avoids complex Flow bridging).
@MainActor
class TtsViewModelWrapper: ObservableObject {

    // MARK: - Published state
    @Published var inputText: String = ""
    @Published var pitch: Float = 1.0
    @Published var rate: Float = 1.0
    @Published var selectedLanguage: TtsLanguage
    @Published var isSpeaking: Bool = false
    @Published var errorMessage: String? = nil
    @Published var history: [TtsHistoryItem] = []

    // MARK: - Languages
    let languages: [TtsLanguage]

    // KMP objects (accessed directly — no Android ViewModel needed)
    private let ttsService: TtsService
    private let repository: IosTtsRepository

    private var pollTimer: Timer?
    private var historyJob: Task<Void, Never>?

    init() {
        let allLangs = TtsLanguageKt.SupportedLanguages
        self.languages = allLangs
        self.selectedLanguage = allLangs.first!
        self.ttsService = TtsService()
        self.repository = IosTtsRepository()

        startPolling()
        startHistoryCollection()
    }

    deinit {
        pollTimer?.invalidate()
        historyJob?.cancel()
        ttsService.shutdown()
    }

    // MARK: - Actions

    func speak() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        ttsService.speak(text: text, pitch: pitch, rate: rate, localeTag: selectedLanguage.tag)
        let item = TtsHistoryItem(
            id: 0,
            text: text,
            pitch: pitch,
            rate: rate,
            timestamp: Int64(Date().timeIntervalSince1970 * 1000)
        )
        Task { try? await repository.addItem(item: item) }
    }

    func stop() {
        ttsService.stop()
    }

    func respeak(_ item: TtsHistoryItem) {
        inputText = item.text
        pitch = item.pitch
        rate = item.rate
        ttsService.speak(text: item.text, pitch: item.pitch, rate: item.rate, localeTag: selectedLanguage.tag)
    }

    func deleteItem(_ item: TtsHistoryItem) {
        Task { try? await repository.deleteItem(id: item.id) }
    }

    func clearHistory() {
        Task { try? await repository.clearAll() }
    }

    // MARK: - Private: poll KMP StateFlow every 200ms

    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let state = self.ttsService.state.value
                if state is TtsState.Speaking {
                    self.isSpeaking = true
                    self.errorMessage = nil
                } else if let err = state as? TtsState.Error {
                    self.isSpeaking = false
                    self.errorMessage = err.message
                } else {
                    self.isSpeaking = false
                    self.errorMessage = nil
                }
            }
        }
    }

    private func startHistoryCollection() {
        historyJob = Task {
            while !Task.isCancelled {
                let items = repository.currentHistory()
                await MainActor.run { self.history = items }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
    }
}
