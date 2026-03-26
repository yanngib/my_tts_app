package com.tts.shared.data

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface TtsHistoryDao {

    @Query("SELECT * FROM tts_history ORDER BY timestamp DESC")
    fun observeAll(): Flow<List<TtsHistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(entity: TtsHistoryEntity)

    @Query("DELETE FROM tts_history WHERE id = :id")
    suspend fun deleteById(id: Long)

    @Query("DELETE FROM tts_history")
    suspend fun clearAll()
}
