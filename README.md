# MyTTS App

A **Kotlin Multiplatform (KMP)** text-to-speech app for **Android** and **iOS**, built with Jetpack Compose (Android) and SwiftUI (iOS), sharing business logic via a common Kotlin module.

## Features

- 🎙️ Text-to-speech with native engine on each platform
- 🌍 Language selector (14 languages including Mandarin, Japanese, Arabic, etc.)
- 🎚️ Pitch and speed controls
- 📜 History log with re-speak and delete
- 💾 Persistent history (Room on Android, NSUserDefaults on iOS)

## Project Structure

```
my_tts_app/
├── shared/                  # KMP shared module
│   └── src/
│       ├── commonMain/      # Shared: TtsRepository, TtsViewModel, TtsService (expect)
│       ├── androidMain/     # Android: TtsService (TextToSpeech), Room DB
│       └── iosMain/         # iOS: TtsService (AVSpeechSynthesizer), NSUserDefaults
├── composeApp/              # Android app (Jetpack Compose)
└── iosApp/                  # iOS app (SwiftUI + KMP framework)
```

## Requirements

| Platform | Requirement |
|----------|-------------|
| Android  | Android 8.0+ (API 26), Android Studio |
| iOS      | iOS 16.0+, Xcode 15+, macOS |

## Getting Started

### Android

```bash
# Build debug APK
./gradlew :composeApp:assembleDebug

# Install directly on connected device / emulator
./gradlew :composeApp:installDebug
```

> If `adb` is not found, add it to your PATH:
> ```bash
> echo 'export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"' >> ~/.zshrc && source ~/.zshrc
> ```

### iOS

**Step 1** — Build the KMP framework:
```bash
JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
  ./gradlew :shared:linkDebugFrameworkIosSimulatorArm64
```

**Step 2** — Open in Xcode:
```bash
open iosApp/iosApp.xcodeproj
```

**Step 3** — Select a simulator or device and press **⌘R**.

> Re-run Step 1 whenever you change Kotlin code in `shared/`.

## Tech Stack

| Layer | Android | iOS |
|-------|---------|-----|
| UI | Jetpack Compose | SwiftUI |
| TTS | `android.speech.tts.TextToSpeech` | `AVSpeechSynthesizer` |
| Persistence | Room | NSUserDefaults |
| Architecture | MVVM (`TtsViewModel`) | `TtsViewModelWrapper` (ObservableObject) |
| Shared | Kotlin Multiplatform | Kotlin Multiplatform |
