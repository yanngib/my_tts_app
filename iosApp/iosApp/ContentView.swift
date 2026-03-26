import SwiftUI
import SharedTts

struct ContentView: View {
    @StateObject private var vm = TtsViewModelWrapper()
    @State private var showHistory = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {

                    // ── Text Input ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Text to Speak", systemImage: "text.bubble")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        TextEditor(text: $vm.inputText)
                            .frame(minHeight: 120)
                            .padding(10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }

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
