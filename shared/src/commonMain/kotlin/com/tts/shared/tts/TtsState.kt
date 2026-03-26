package com.tts.shared.tts

/**
 * Represents the current state of the TTS engine.
 */
sealed class TtsState {
    object Idle : TtsState()
    object Speaking : TtsState()
    data class Error(val message: String) : TtsState()
}
