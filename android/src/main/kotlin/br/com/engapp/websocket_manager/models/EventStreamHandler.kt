package br.com.engapp.websocket_manager

import android.util.Log
import io.flutter.plugin.common.EventChannel

class EventStreamHandler(
    private val onNullSink: () -> Unit,
    private val onCancelCallback: () -> Unit
) : EventChannel.StreamHandler {

    private var sink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        Log.i("EventStreamHandler", "🔴 onListen arguments: $arguments")
        sink = eventSink
    }

    override fun onCancel(arguments: Any?) {
        Log.i("EventStreamHandler", "onCancel")
        sink = null
        onCancelCallback()
    }

    fun send(data: Any?) {
        val s = sink
        if (s != null) {
            Log.i("EventStreamHandler", "✅ sink is not null")
            try {
                s.success(data)
            } catch (e: Exception) {
                Log.i("EventStreamHandler", "Exception while sending: ${e.message}")
            }
        } else {
            Log.i("EventStreamHandler", "❌ sink is null")
            onNullSink()
        }
    }
}
