package com.tts.shared.tts

/**
 * Represents a supported TTS language.
 * [tag] is a BCP-47 locale tag passed to [Locale.forLanguageTag] on Android.
 */
data class TtsLanguage(val displayName: String, val tag: String)

val SupportedLanguages = listOf(
    TtsLanguage("English (US)", "en-US"),
    TtsLanguage("English (UK)", "en-GB"),
    TtsLanguage("Spanish (ES)", "es-ES"),
    TtsLanguage("Spanish (MX)", "es-MX"),
    TtsLanguage("French", "fr-FR"),
    TtsLanguage("German", "de-DE"),
    TtsLanguage("Italian", "it-IT"),
    TtsLanguage("Portuguese (BR)", "pt-BR"),
    TtsLanguage("Japanese", "ja-JP"),
    TtsLanguage("Korean", "ko-KR"),
    TtsLanguage("Chinese (Mandarin)", "zh-CN"),
    TtsLanguage("Arabic", "ar-SA"),
    TtsLanguage("Hindi", "hi-IN"),
    TtsLanguage("Russian", "ru-RU"),
)
