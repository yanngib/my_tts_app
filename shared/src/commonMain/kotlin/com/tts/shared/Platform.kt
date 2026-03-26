package com.tts.shared

/**
 * Returns the current time in milliseconds since epoch.
 * Each platform provides its own actual implementation.
 */
expect fun currentTimeMillis(): Long
