package com.tts.shared.data

import com.tts.shared.currentTimeMillis
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import platform.Foundation.NSUserDefaults

/**
 * iOS implementation of [TtsRepository] backed by NSUserDefaults JSON serialization.
 *
 * Format: one entry per line — "id|text|pitch|rate|timestamp|languageTag"
 * (languageTag is optional for backward compat with v1 records)
 */
class IosTtsRepository : TtsRepository {

    private val defaults = NSUserDefaults.standardUserDefaults
    private val key = "tts_history"

    private val _history = MutableStateFlow<List<TtsHistoryItem>>(emptyList())

    init {
        _history.value = loadFromDefaults()
    }

    override fun getHistory(): Flow<List<TtsHistoryItem>> = _history.asStateFlow()

    fun currentHistory(): List<TtsHistoryItem> = _history.value

    override suspend fun addItem(item: TtsHistoryItem) {
        val updated = listOf(item.copy(id = currentTimeMillis())) + _history.value
        _history.value = updated
        saveToDefaults(updated)
    }

    override suspend fun deleteItem(id: Long) {
        val updated = _history.value.filter { it.id != id }
        _history.value = updated
        saveToDefaults(updated)
    }

    override suspend fun clearAll() {
        _history.value = emptyList()
        defaults.removeObjectForKey(key)
    }

    // Persist as: "id|text|pitch|rate|timestamp|languageTag"
    // (pipe chars inside text are escaped as \|)
    private fun saveToDefaults(items: List<TtsHistoryItem>) {
        val encoded = items.joinToString(separator = "\n") { item ->
            val safeText = item.text.replace("|", "\\|")
            "${item.id}|${safeText}|${item.pitch}|${item.rate}|${item.timestamp}|${item.languageTag}"
        }
        defaults.setObject(encoded, forKey = key)
    }

    private fun loadFromDefaults(): List<TtsHistoryItem> {
        val raw = defaults.stringForKey(key) ?: return emptyList()
        if (raw.isBlank()) return emptyList()
        return raw.lines().mapNotNull { line ->
            val parts = line.split("|")
            if (parts.size < 5) return@mapNotNull null
            try {
                TtsHistoryItem(
                    id           = parts[0].toLong(),
                    text         = parts[1].replace("\\|", "|"),
                    pitch        = parts[2].toFloat(),
                    rate         = parts[3].toFloat(),
                    timestamp    = parts[4].toLong(),
                    languageTag  = if (parts.size >= 6) parts[5] else ""   // backward compat
                )
            } catch (_: Exception) {
                null
            }
        }
    }
}
