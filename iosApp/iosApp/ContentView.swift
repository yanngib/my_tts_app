import SwiftUI
import SharedTts

struct ContentView: View {
    @StateObject private var vm = TtsViewModelWrapper()
    @StateObject private var speech = SpeechRecognizer()
    @State private var showHistory = false
    @FocusState private var isEditing: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Text Input ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .center) {
                            Label("Text to Speak", systemImage: "text.bubble")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Spacer()
                            // Press-and-hold mic button
                            MicButton(isRecording: speech.isRecording) { pressing in
                                if pressing {
                                    isEditing = false
                                    vm.inputText = ""        // clear immediately on press
                                    speech.startRecording(localeTag: vm.selectedLanguage.tag)
                                } else {
                                    let result = speech.stopRecording()
                                    vm.inputText = result    // write final transcript on release
                                }
                            }
                        }
                        TextEditor(text: $vm.inputText)
                            .focused($isEditing)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        speech.isRecording
                                            ? Color.red.opacity(0.7)
                                            : Color.accentColor.opacity(0.3),
                                        lineWidth: speech.isRecording ? 2 : 1
                                    )
                            )
                            .onChange(of: speech.transcript) { newValue in
                                if speech.isRecording {
                                    vm.inputText = newValue  // stream live partial text into the box
                                }
                            }
                    }
                    .onAppear { speech.requestPermissions() }

                    // ── Language Picker ───────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Language", systemImage: "globe")
                            .font(.headline)
                        Picker("Language", selection: $vm.selectedLanguage) {
                            ForEach(vm.languages, id: \.tag) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // ── Pitch Slider ──────────────────────────────────────
                    SliderRow(
                        label: "Pitch",
                        systemImage: "waveform",
                        value: $vm.pitch,
                        range: 0.5...2.0
                    )

                    // ── Rate Slider ───────────────────────────────────────
                    SliderRow(
                        label: "Speed",
                        systemImage: "speedometer",
                        value: $vm.rate,
                        range: 0.25...2.0
                    )

                    // ── Error Banner ──────────────────────────────────────
                    if let error = vm.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.callout)
                                .foregroundStyle(.red)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    // ── Action Buttons ────────────────────────────────────
                    HStack(spacing: 16) {
                        Button {
                            if vm.isSpeaking { vm.stop() } else { vm.speak() }
                        } label: {
                            Label(
                                vm.isSpeaking ? "Stop" : "Speak",
                                systemImage: vm.isSpeaking ? "stop.fill" : "play.fill"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(vm.isSpeaking ? .red : .accentColor)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
            .onTapGesture { isEditing = false }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("TTS App")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showHistory = true
                    } label: {
                        Image(systemName: "clock.arrow.trianglehead.counterclockwise.rotate.90")
                    }
                }
            }
            .sheet(isPresented: $showHistory) {
                HistoryView(vm: vm)
            }
        }
    }
}

// MARK: - Mic Button
/// A press-and-hold button that signals recording state via a Boolean closure.
private struct MicButton: View {
    let isRecording: Bool
    /// Called with `true` when the press begins, `false` when released.
    let onPressChange: (Bool) -> Void

    var body: some View {
        Image(systemName: isRecording ? "mic.fill" : "mic")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(isRecording ? .white : .accentColor)
            .padding(10)
            .background(
                isRecording
                    ? AnyShapeStyle(Color.red)
                    : AnyShapeStyle(Color.accentColor.opacity(0.12))
            )
            .clipShape(Circle())
            .scaleEffect(isRecording ? 1.15 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isRecording)
            // Pulse ring while recording
            .overlay {
                if isRecording {
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 3)
                        .scaleEffect(1.4)
                        .animation(
                            .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                            value: isRecording
                        )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isRecording { onPressChange(true) }
                    }
                    .onEnded { _ in
                        onPressChange(false)
                    }
            )
            .accessibilityLabel(isRecording ? "Stop recording" : "Record voice input")
            .accessibilityHint(isRecording ? "Release to transcribe" : "Hold to record")
    }
}

// MARK: - Slider Row
private struct SliderRow: View {
    let label: String
    let systemImage: String
    @Binding var value: Float
    let range: ClosedRange<Float>

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(label, systemImage: systemImage)
                    .font(.headline)
                Spacer()
                Text(String(format: "%.2f", value))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: $value, in: range)
                .tint(.accentColor)
        }
        .padding(.horizontal, 4)
    }
}

#Preview {
    ContentView()
}
