import Foundation
import AVFoundation
import Speech

/// Handles press-and-hold voice recording and real-time transcription.
/// Requires NSMicrophoneUsageDescription and NSSpeechRecognitionUsageDescription in Info.plist.
@MainActor
final class SpeechRecognizer: ObservableObject {

    // MARK: - Published state

    @Published var isRecording = false
    @Published var transcript: String = ""
    @Published var errorMessage: String? = nil

    // MARK: - Private

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?

    // MARK: - Public API

    /// Request microphone + speech permissions upfront.
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { _ in }
        AVAudioSession.sharedInstance().requestRecordPermission { _ in }
    }

    /// Start recording and streaming audio to the speech recognizer.
    /// - Parameter localeTag: BCP-47 tag matching the selected TTS language (e.g. "en-US").
    func startRecording(localeTag: String = Locale.current.identifier) {
        errorMessage = nil
        transcript = ""

        // Use the supplied locale; fall back to en-US if unavailable.
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: localeTag))
                        ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available."
            return
        }

        // Configure audio session for recording.
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let request = recognitionRequest else { return }
        request.shouldReportPartialResults = true

        // Tap the microphone input.
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Audio engine failed to start: \(error.localizedDescription)"
            return
        }

        isRecording = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }
            if let error {
                // Ignore cancellation errors (triggered on stopRecording).
                let nsErr = error as NSError
                if nsErr.domain != "kAFAssistantErrorDomain" && nsErr.code != 216 && nsErr.code != 203 {
                    Task { @MainActor in
                        self.errorMessage = error.localizedDescription
                    }
                }
            }
        }
    }

    /// Stop recording and finalize the transcript.
    /// - Returns: The final transcribed string.
    @discardableResult
    func stopRecording() -> String {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        // Switch audio session back to playback so AVSpeechSynthesizer can use the speaker.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        return transcript
    }
}
