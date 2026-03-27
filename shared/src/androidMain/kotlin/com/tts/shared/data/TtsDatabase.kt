package com.tts.shared.data

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import android.content.Context

val MIGRATION_1_2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE tts_history ADD COLUMN languageTag TEXT NOT NULL DEFAULT ''")
    }
}

@Database(entities = [TtsHistoryEntity::class], version = 2, exportSchema = true)
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
                )
                    .addMigrations(MIGRATION_1_2)
                    .build().also { INSTANCE = it }
            }
    }
}
