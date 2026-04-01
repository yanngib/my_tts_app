package com.tts.shared.data

import app.cash.sqldelight.driver.native.NativeSqliteDriver
import com.tts.shared.currentTimeMillis
import com.tts.shared.database.TtsHistoryDatabase
import com.tts.shared.database.TtsHistoryEntry
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * iOS implementation of [TtsRepository] backed by SQLite via SQLDelight.
 * The database file lives in the app's default SQLite directory (managed by NativeSqliteDriver).
 */
class IosTtsRepository : TtsRepository {

    private val driver = NativeSqliteDriver(TtsHistoryDatabase.Schema, "tts_history.db")
    private val database = TtsHistoryDatabase(driver)
    private val queries = database.ttsHistoryQueries

    private val _history = MutableStateFlow<List<TtsHistoryItem>>(emptyList())

    init {
        _history.value = fetchAll()
    }

    override fun getHistory(): Flow<List<TtsHistoryItem>> = _history.asStateFlow()

    fun currentHistory(): List<TtsHistoryItem> = _history.value

    override suspend fun addItem(item: TtsHistoryItem) {
        queries.insert(
            text        = item.text,
            pitch       = item.pitch.toDouble(),
            rate        = item.rate.toDouble(),
            timestamp   = currentTimeMillis(),
            languageTag = item.languageTag
        )
        _history.value = fetchAll()
    }

    override suspend fun deleteItem(id: Long) {
        queries.deleteById(id)
        _history.value = fetchAll()
    }

    override suspend fun clearAll() {
        queries.deleteAll()
        _history.value = emptyList()
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    private fun fetchAll(): List<TtsHistoryItem> =
        queries.selectAll().executeAsList().map { it.toDomain() }
}

private fun TtsHistoryEntry.toDomain() = TtsHistoryItem(
    id          = id,
    text        = text,
    pitch       = pitch.toFloat(),
    rate        = rate.toFloat(),
    timestamp   = timestamp,
    languageTag = languageTag
)
