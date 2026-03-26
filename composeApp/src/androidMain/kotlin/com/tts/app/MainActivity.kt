package com.tts.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel
import com.tts.shared.data.createTtsRepository
import com.tts.shared.tts.TtsService
import com.tts.shared.viewmodel.TtsViewModel

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // Wire up dependencies via shared factory (no Room types exposed here)
        val ttsService = TtsService(applicationContext)
        val repository = createTtsRepository(applicationContext)

        setContent {
            val vm: TtsViewModel = viewModel(
                factory = object : ViewModelProvider.Factory {
                    @Suppress("UNCHECKED_CAST")
                    override fun <T : ViewModel> create(modelClass: Class<T>): T =
                        TtsViewModel(ttsService, repository) as T
                }
            )
            App(vm)
        }
    }
}
