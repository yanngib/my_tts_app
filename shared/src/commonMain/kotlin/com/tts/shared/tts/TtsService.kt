package com.tts.shared.tts

import kotlinx.coroutines.flow.StateFlow

/**
 * Expect declaration for the TTS service.
 * Each platform provides its own actual implementation.
 */
expect class TtsService {
    val state: StateFlow<TtsState>
    fun speak(text: String, pitch: Float, rate: Float, localeTag: String)
    fun stop()
    fun shutdown()
}
