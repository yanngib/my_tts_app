package com.tts.shared.tts

import android.content.Context
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.Locale

/**
 * Android actual implementation of [TtsService] using the native [TextToSpeech] engine.
 */
actual class TtsService(context: Context) {

    private val _state = MutableStateFlow<TtsState>(TtsState.Idle)
    actual val state: StateFlow<TtsState> = _state.asStateFlow()

    private var tts: TextToSpeech? = null

    init {
        tts = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                tts?.language = Locale.getDefault()
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) {
                        _state.value = TtsState.Speaking
                    }

                    override fun onDone(utteranceId: String?) {
                        _state.value = TtsState.Idle
                    }

                    @Deprecated("Deprecated in Java")
                    override fun onError(utteranceId: String?) {
                        _state.value = TtsState.Error("TTS error")
                    }

                    override fun onError(utteranceId: String?, errorCode: Int) {
                        _state.value = TtsState.Error("TTS error code: $errorCode")
                    }
                })
            } else {
                _state.value = TtsState.Error("TTS initialization failed")
            }
        }
    }

    actual fun speak(text: String, pitch: Float, rate: Float, localeTag: String) {
        tts?.apply {
            language = Locale.forLanguageTag(localeTag)
            setPitch(pitch)
            setSpeechRate(rate)
            speak(text, TextToSpeech.QUEUE_FLUSH, null, UTTERANCE_ID)
        }
    }

    actual fun stop() {
        tts?.stop()
        _state.value = TtsState.Idle
    }

    actual fun shutdown() {
        tts?.stop()
        tts?.shutdown()
        tts = null
    }

    companion object {
        private const val UTTERANCE_ID = "tts_utterance"
    }
}
