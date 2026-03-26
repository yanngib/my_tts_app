package com.tts.shared.tts

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import platform.AVFAudio.AVSpeechBoundary
import platform.AVFAudio.AVSpeechSynthesisVoice
import platform.AVFAudio.AVSpeechSynthesizer
import platform.AVFAudio.AVSpeechSynthesizerDelegateProtocol
import platform.AVFAudio.AVSpeechUtterance
import platform.Foundation.NSRunLoop
import platform.Foundation.NSTimer
import platform.Foundation.NSDefaultRunLoopMode
import platform.darwin.NSObject

/**
 * iOS actual implementation of [TtsService] using AVSpeechSynthesizer.
 *
 * Uses an NSTimer to poll synthesizer.isSpeaking (instead of the delegate's
 * didFinish/didCancel, which have conflicting Kotlin signatures).
 */
actual class TtsService {

    private val _state = MutableStateFlow<TtsState>(TtsState.Idle)
    actual val state: StateFlow<TtsState> = _state.asStateFlow()

    private val synthesizer = AVSpeechSynthesizer()
    private var pollTimer: NSTimer? = null

    private val delegate = object : NSObject(), AVSpeechSynthesizerDelegateProtocol {
        override fun speechSynthesizer(
            synthesizer: AVSpeechSynthesizer,
            didStartSpeechUtterance: AVSpeechUtterance
        ) {
            _state.value = TtsState.Speaking
            startPolling()
        }
    }

    init {
        synthesizer.delegate = delegate
    }

    actual fun speak(text: String, pitch: Float, rate: Float, localeTag: String) {
        synthesizer.stopSpeakingAtBoundary(AVSpeechBoundary.AVSpeechBoundaryImmediate)
        val utterance = AVSpeechUtterance(string = text)
        utterance.voice = AVSpeechSynthesisVoice.voiceWithLanguage(localeTag)
            ?: AVSpeechSynthesisVoice.voiceWithLanguage("en-US")
        utterance.rate = rate.coerceIn(0.25f, 2.0f) / 2.0f * 0.8f + 0.1f
        utterance.pitchMultiplier = pitch.coerceIn(0.5f, 2.0f)
        synthesizer.speakUtterance(utterance)
    }

    actual fun stop() {
        synthesizer.stopSpeakingAtBoundary(AVSpeechBoundary.AVSpeechBoundaryImmediate)
        stopPolling()
        _state.value = TtsState.Idle
    }

    actual fun shutdown() {
        stop()
    }

    private fun startPolling() {
        stopPolling()
        val timer = NSTimer.timerWithTimeInterval(
            interval = 0.15,
            repeats = true,
            block = { _ ->
                if (!synthesizer.speaking) {
                    _state.value = TtsState.Idle
                    stopPolling()
                }
            }
        )
        NSRunLoop.currentRunLoop.addTimer(timer, forMode = NSDefaultRunLoopMode)
        pollTimer = timer
    }

    private fun stopPolling() {
        pollTimer?.invalidate()
        pollTimer = null
    }
}
