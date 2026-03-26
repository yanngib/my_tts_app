package com.tts.shared.data

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import android.content.Context

@Database(entities = [TtsHistoryEntity::class], version = 1, exportSchema = true)
abstract class TtsDatabase : RoomDatabase() {
    abstract fun dao(): TtsHistoryDao

    companion object {
        @Volatile
        private var INSTANCE: TtsDatabase? = null

        fun getInstance(context: Context): TtsDatabase =
            INSTANCE ?: synchronized(this) {
                Room.databaseBuilder(
                    context.applicationContext,
                    TtsDatabase::class.java,
                    "tts_history.db"
                ).build().also { INSTANCE = it }
            }
    }
}
