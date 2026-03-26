package com.tts.app

import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.RecordVoiceOver
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.tts.app.navigation.Screen
import com.tts.app.ui.HistoryScreen
import com.tts.app.ui.TtsScreen
import com.tts.app.ui.theme.TtsAppTheme
import com.tts.shared.viewmodel.TtsViewModel

@Composable
fun App(viewModel: TtsViewModel) {
    TtsAppTheme {
        val navController = rememberNavController()
        Scaffold(
            bottomBar = { BottomNav(navController) }
        ) { paddingValues ->
            NavHost(
                navController = navController,
                startDestination = Screen.Tts.route,
                modifier = androidx.compose.ui.Modifier.also { /* padding applied inside screens */ }
            ) {
                composable(Screen.Tts.route) {
                    TtsScreen(viewModel = viewModel, paddingValues = paddingValues)
                }
                composable(Screen.History.route) {
                    HistoryScreen(viewModel = viewModel, paddingValues = paddingValues)
                }
            }
        }
    }
}

@Composable
private fun BottomNav(navController: NavHostController) {
    val backStack by navController.currentBackStackEntryAsState()
    val currentRoute = backStack?.destination?.route

    NavigationBar {
        NavigationBarItem(
            selected = currentRoute == Screen.Tts.route,
            onClick = {
                navController.navigate(Screen.Tts.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            },
            icon = { Icon(Icons.Default.RecordVoiceOver, contentDescription = "TTS") },
            label = { Text("Speak") }
        )
        NavigationBarItem(
            selected = currentRoute == Screen.History.route,
            onClick = {
                navController.navigate(Screen.History.route) {
                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                    launchSingleTop = true
                    restoreState = true
                }
            },
            icon = { Icon(Icons.Default.History, contentDescription = "History") },
            label = { Text("History") }
        )
    }
}
