package com.tts.app.navigation

sealed class Screen(val route: String) {
    object Tts : Screen("tts")
    object History : Screen("history")
}
