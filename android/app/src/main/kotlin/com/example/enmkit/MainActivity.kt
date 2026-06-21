package com.example.enmkit

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

// Branche les canaux natifs utilises par le pont SMS en arriere-plan :
// - MethodChannel "enmkit/sms_background" : setKitNumbers / drainPending
// - EventChannel  "enmkit/sms_background_events" : reveil Dart a la reception
class MainActivity : FlutterFragmentActivity() {
    private val methodChannelName = "enmkit/sms_background"
    private val eventChannelName = "enmkit/sms_background_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        val store = SmsStore(applicationContext)

        MethodChannel(messenger, methodChannelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "setKitNumbers" -> {
                    val numbers = call.argument<List<String>>("numbers") ?: emptyList()
                    store.setKitNumbers(numbers)
                    result.success(true)
                }
                "drainPending" -> {
                    result.success(store.drain())
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(messenger, eventChannelName).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    SmsEventBridge.attach(events)
                }

                override fun onCancel(arguments: Any?) {
                    SmsEventBridge.detach()
                }
            }
        )
    }
}
