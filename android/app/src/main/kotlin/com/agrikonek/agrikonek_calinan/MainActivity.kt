package com.agrikonek.agrikonek_calinan

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createAlertChannel()
    }

    // Android 8+ shows a push only through a notification channel. The
    // Cloud Function sends every push on this channel ID, and the manifest
    // names it as the FCM default. High importance makes bid and barter
    // alerts pop up on screen instead of arriving silently.
    private fun createAlertChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            ALERT_CHANNEL_ID,
            "Bids and barters / Tanyag ug baylo",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "New offers, barter proposals, messages and announcements"
        }
        getSystemService(NotificationManager::class.java)
            ?.createNotificationChannel(channel)
    }

    companion object {
        const val ALERT_CHANNEL_ID = "agrikonek_alerts"
    }
}
