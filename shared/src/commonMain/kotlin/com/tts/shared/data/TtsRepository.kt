package com.tts.shared.data

import kotlinx.coroutines.flow.Flow

/**
 * Repository interface for TTS history persistence.
 * Platform-specific implementations provide the actual storage.
 */
interface TtsRepository {
    fun getHistory(): Flow<List<TtsHistoryItem>>
    suspend fun addItem(item: TtsHistoryItem)
    suspend fun deleteItem(id: Long)
    suspend fun clearAll()
}
