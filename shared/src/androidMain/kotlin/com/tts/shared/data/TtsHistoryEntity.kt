package com.tts.shared.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "tts_history")
data class TtsHistoryEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0L,
    val text: String,
    val pitch: Float,
    val rate: Float,
    val timestamp: Long,
    val languageTag: String = ""
)

fun TtsHistoryEntity.toDomain(): TtsHistoryItem =
    TtsHistoryItem(id = id, text = text, pitch = pitch, rate = rate, timestamp = timestamp, languageTag = languageTag)

fun TtsHistoryItem.toEntity(): TtsHistoryEntity =
    TtsHistoryEntity(id = id, text = text, pitch = pitch, rate = rate, timestamp = timestamp, languageTag = languageTag)
