package com.tts.shared.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class RoomTtsRepository(private val dao: TtsHistoryDao) : TtsRepository {

    override fun getHistory(): Flow<List<TtsHistoryItem>> =
        dao.observeAll().map { list -> list.map { it.toDomain() } }

    override suspend fun addItem(item: TtsHistoryItem) {
        dao.insert(item.toEntity())
    }

    override suspend fun deleteItem(id: Long) {
        dao.deleteById(id)
    }

    override suspend fun clearAll() {
        dao.clearAll()
    }
}
