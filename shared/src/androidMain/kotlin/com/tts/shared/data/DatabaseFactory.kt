package com.tts.shared.data

import android.content.Context

/**
 * Factory function so [composeApp] doesn't need Room on its own classpath.
 */
fun createTtsRepository(context: Context): TtsRepository =
    RoomTtsRepository(TtsDatabase.getInstance(context).dao())
