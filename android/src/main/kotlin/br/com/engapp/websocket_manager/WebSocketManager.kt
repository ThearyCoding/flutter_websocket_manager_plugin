package br.com.engapp.websocket_manager

import android.os.Handler
import android.os.Looper
import android.util.Log
import okhttp3.*
import okio.ByteString
import java.util.concurrent.TimeUnit
import kotlin.math.min
import kotlin.math.pow

class StreamWebSocketManager : WebSocketListener() {

    private val uiHandler: Handler = Handler(Looper.getMainLooper())

    // ✅ IMPORTANT: keep-alive ping (< pusher activity_timeout=30)
    private val client: OkHttpClient = OkHttpClient.Builder()
        .pingInterval(15, TimeUnit.SECONDS)
        .readTimeout(0, TimeUnit.MILLISECONDS) // WebSocket shouldn't use read timeout
        .retryOnConnectionFailure(true)
        .build()

    private var ws: WebSocket? = null
    private var url: String? = null
    private var header: Map<String, String>? = null

    var messageCallback: ((String) -> Unit)? = null
    var closeCallback: ((String) -> Unit)? = null
    var openCallback: ((String) -> Unit)? = null
    var connectedCallback: ((Boolean) -> Unit)? = null
    var errorCallback: ((String) -> Unit)? = null

    var enableRetries: Boolean = true
    private var reconnectAttempts = 0
    private val maxReconnectDelay = 30L // seconds
    private var isManuallyClosed = false

    private enum class State { DISCONNECTED, CONNECTING, CONNECTED }
    private var state: State = State.DISCONNECTED

    fun create(url: String, header: Map<String, String>?) {
        this.url = url
        this.header = header
        reconnectAttempts = 0
        isManuallyClosed = false
        state = State.DISCONNECTED
    }

    fun connect() {
        val u = url ?: return

        // ✅ avoid duplicate connect() calls
        if (state == State.CONNECTED || state == State.CONNECTING) return

        state = State.CONNECTING
        isManuallyClosed = false

        val requestBuilder = Request.Builder().url(u)
        header?.forEach { (key, value) -> requestBuilder.addHeader(key, value) }
        val request = requestBuilder.build()

        ws = client.newWebSocket(request, this)
    }

    fun disconnect() {
        isManuallyClosed = true
        enableRetries = false

        // ✅ close gracefully, then cancel as a fallback
        ws?.close(1000, "Manual disconnect")
        ws?.cancel()

        ws = null
        state = State.DISCONNECTED

        uiHandler.post { connectedCallback?.invoke(false) }
        uiHandler.post { closeCallback?.invoke("closed") }
    }

    fun send(msg: String) {
        ws?.send(msg)
    }

    // Optional echo test
    fun echoTest() {
        var count = 0
        url = "wss://echo.websocket.org"
        openCallback = { sendMessage(count++) }
        messageCallback = {
            if (count >= 10) disconnect() else sendMessage(count++)
        }
        connect()
    }

    private fun sendMessage(count: Int) {
        val msg = "$count: ${System.currentTimeMillis()}"
        ws?.send(msg)
    }

    // ---- WebSocketListener overrides ----

    override fun onOpen(webSocket: WebSocket, response: Response) {
        reconnectAttempts = 0
        state = State.CONNECTED

        uiHandler.post { connectedCallback?.invoke(true) }
        uiHandler.post { openCallback?.invoke(response.message) }
    }

    override fun onMessage(webSocket: WebSocket, text: String) {
        uiHandler.post { messageCallback?.invoke(text) }
    }

    override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
        // Handle binary messages if needed
    }

    override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        Log.w("GlobalSocket", "Socket closing: code=$code reason=$reason")
        // Don't schedule here; wait for onClosed/onFailure (more reliable)
    }

    override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        Log.w("GlobalSocket", "Socket closed: code=$code reason=$reason")

        ws = null
        state = State.DISCONNECTED

        uiHandler.post { connectedCallback?.invoke(false) }

        if (!isManuallyClosed && enableRetries) {
            scheduleReconnect()
        } else {
            uiHandler.post { closeCallback?.invoke("closed") }
        }
    }

    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        Log.e("GlobalSocket", "Socket failure: ${t.message}", t)

        ws = null
        state = State.DISCONNECTED

        val respInfo = if (response != null) " (http=${response.code} ${response.message})" else ""
        uiHandler.post { errorCallback?.invoke((t.message ?: "WebSocket error") + respInfo) }

        uiHandler.post { connectedCallback?.invoke(false) }
        uiHandler.post { closeCallback?.invoke("failed") }

        if (!isManuallyClosed && enableRetries) {
            scheduleReconnect()
        }
    }

    private fun scheduleReconnect() {
        // ✅ if someone already called connect again, don't double schedule
        if (state == State.CONNECTING || state == State.CONNECTED) return

        reconnectAttempts++
        val delay = min(2.0.pow(reconnectAttempts.toDouble()).toLong(), maxReconnectDelay)
        Log.i("GlobalSocket", "Reconnecting in ${delay}s (attempt=$reconnectAttempts)")

        uiHandler.postDelayed({ connect() }, delay * 1000)
    }

    fun isConnected(): Boolean = state == State.CONNECTED
}
