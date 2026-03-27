package com.tts.shared.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.tts.shared.data.TtsHistoryItem
import com.tts.shared.data.TtsRepository
import com.tts.shared.tts.SupportedLanguages
import com.tts.shared.tts.TtsLanguage
import com.tts.shared.tts.TtsService
import com.tts.shared.tts.TtsState
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import com.tts.shared.currentTimeMillis
import kotlinx.coroutines.launch

data class TtsUiState(
    val inputText: String = "",
    val pitch: Float = 1.0f,
    val rate: Float = 1.0f,
    val selectedLanguage: TtsLanguage = SupportedLanguages.first(),
    val ttsState: TtsState = TtsState.Idle,
    val history: List<TtsHistoryItem> = emptyList()
)

class TtsViewModel(
    private val ttsService: TtsService,
    private val repository: TtsRepository
) : ViewModel() {

    private val _inputText = MutableStateFlow("")
    private val _pitch = MutableStateFlow(1.0f)
    private val _rate = MutableStateFlow(1.0f)
    private val _language = MutableStateFlow(SupportedLanguages.first())

    val uiState: StateFlow<TtsUiState> = combine(
        combine(_inputText, _pitch, _rate, _language) { text, pitch, rate, lang ->
            Triple(text, pitch, Pair(rate, lang))
        },
        ttsService.state,
        repository.getHistory()
    ) { textPitchRateLang, ttsState, history ->
        val text = textPitchRateLang.first
        val pitch = textPitchRateLang.second
        val rateLang = textPitchRateLang.third
        val rate = rateLang.first
        val lang = rateLang.second
        TtsUiState(
            inputText = text,
            pitch = pitch,
            rate = rate,
            selectedLanguage = lang,
            ttsState = ttsState,
            history = history
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = TtsUiState()
    )

    fun onTextChange(text: String) {
        _inputText.update { text }
    }

    fun onPitchChange(pitch: Float) {
        _pitch.update { pitch }
    }

    fun onLanguageChange(language: TtsLanguage) {
        _language.update { language }
    }

    fun onRateChange(rate: Float) {
        _rate.update { rate }
    }

    fun onSpeak() {
        val text = _inputText.value.trim()
        if (text.isBlank()) return
        val pitch = _pitch.value
        val rate = _rate.value
        val localeTag = _language.value.tag
        ttsService.speak(text, pitch, rate, localeTag)
        viewModelScope.launch {
            repository.addItem(
                TtsHistoryItem(
                    text = text,
                    pitch = pitch,
                    rate = rate,
                    timestamp = currentTimeMillis(),
                    languageTag = _language.value.tag
                )
            )
        }
    }

    fun onStop() {
        ttsService.stop()
    }

    fun onRespeak(item: TtsHistoryItem) {
        _inputText.update { item.text }
        _pitch.update { item.pitch }
        _rate.update { item.rate }
        // Restore the language the text was originally spoken in (if available)
        if (item.languageTag.isNotEmpty()) {
            val lang = SupportedLanguages.find { it.tag == item.languageTag }
            if (lang != null) _language.update { lang }
        }
        val localeTag = if (item.languageTag.isNotEmpty()) item.languageTag else _language.value.tag
        ttsService.speak(item.text, item.pitch, item.rate, localeTag)
    }

    fun onDeleteItem(id: Long) {
        viewModelScope.launch { repository.deleteItem(id) }
    }

    fun onClearHistory() {
        viewModelScope.launch { repository.clearAll() }
    }

    override fun onCleared() {
        super.onCleared()
        ttsService.shutdown()
    }
}
