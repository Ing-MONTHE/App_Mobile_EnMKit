package com.example.enmkit

import io.flutter.plugin.common.EventChannel

// Pont d'evenements : permet au BroadcastReceiver de reveiller le code Dart
// (via EventChannel) quand un SMS de kit arrive pendant que l'app est vivante.
object SmsEventBridge {
    private var sink: EventChannel.EventSink? = null

    fun attach(sink: EventChannel.EventSink?) {
        this.sink = sink
    }

    fun detach() {
        this.sink = null
    }

    fun notifyNewSms() {
        // Le sink doit etre utilise sur le thread principal.
        android.os.Handler(android.os.Looper.getMainLooper()).post {
            sink?.success(1)
        }
    }
}
