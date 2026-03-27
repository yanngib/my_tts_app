package com.tts.shared.data

/**
 * Domain model representing a spoken text history entry.
 */
data class TtsHistoryItem(
    val id: Long = 0L,
    val text: String,
    val pitch: Float,
    val rate: Float,
    val timestamp: Long,
    val languageTag: String = ""   // BCP-47 of the language spoken, e.g. "en-US"
)
