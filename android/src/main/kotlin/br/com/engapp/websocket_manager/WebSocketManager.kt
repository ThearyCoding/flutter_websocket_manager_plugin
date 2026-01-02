package br.com.engapp.websocket_manager

import android.os.Handler
import android.os.Looper
import okhttp3.*
import okio.ByteString
import kotlin.math.min
import kotlin.math.pow

class StreamWebSocketManager : WebSocketListener() {

    private val uiHandler: Handler = Handler(Looper.getMainLooper())
    private val client = OkHttpClient()
    private var ws: WebSocket? = null
    private var url: String? = null
    private var header: Map<String, String>? = null

    var messageCallback: ((String) -> Unit)? = null
    var closeCallback: ((String) -> Unit)? = null
    var openCallback: ((String) -> Unit)? = null
    var connectedCallback: ((Boolean) -> Unit)? = null

    var enableRetries: Boolean = true
    private var reconnectAttempts = 0
    private val maxReconnectDelay = 30L // seconds
    private var isManuallyClosed = false

    fun create(url: String, header: Map<String, String>?) {
        this.url = url
        this.header = header
        reconnectAttempts = 0
        isManuallyClosed = false
    }

    fun connect() {
        if (url == null) return

        val requestBuilder = Request.Builder().url(url!!)
        header?.forEach { (key, value) -> requestBuilder.addHeader(key, value) }
        val request = requestBuilder.build()
        ws = client.newWebSocket(request, this)
    }

    fun disconnect() {
        isManuallyClosed = true
        enableRetries = false
        ws?.close(1000, "Manual disconnect")
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
        connectedCallback?.let { uiHandler.post { it(true) } }
        openCallback?.let { uiHandler.post { it(response.message) } }
    }

    override fun onMessage(webSocket: WebSocket, text: String) {
        messageCallback?.let { uiHandler.post { it(text) } }
    }

    override fun onMessage(webSocket: WebSocket, bytes: ByteString) {
        // Handle binary messages if needed
    }

    override fun onClosing(webSocket: WebSocket, code: Int, reason: String) {
        if (!isManuallyClosed && enableRetries) {
            scheduleReconnect()
        } else {
            uiHandler.post { closeCallback?.invoke("closed") }
        }
    }

    override fun onClosed(webSocket: WebSocket, code: Int, reason: String) {
        uiHandler.post { connectedCallback?.invoke(false) }
        if (!isManuallyClosed && enableRetries) {
            scheduleReconnect()
        } else {
            uiHandler.post { closeCallback?.invoke("closed") }
        }
    }

    override fun onFailure(webSocket: WebSocket, t: Throwable, response: Response?) {
        t.printStackTrace()
        uiHandler.post { closeCallback?.invoke("failed") }
        if (!isManuallyClosed && enableRetries) {
            scheduleReconnect()
        }
    }

    private fun scheduleReconnect() {
        reconnectAttempts++
        val delay = min(2.0.pow(reconnectAttempts.toDouble()).toLong(), maxReconnectDelay)
        uiHandler.postDelayed({ connect() }, delay * 1000)
    }

    fun isConnected(): Boolean = ws != null
}
