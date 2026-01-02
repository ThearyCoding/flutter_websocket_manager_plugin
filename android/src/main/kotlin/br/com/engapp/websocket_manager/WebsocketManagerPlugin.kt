package br.com.engapp.websocket_manager

import android.content.Context
import br.com.engapp.websocket_manager.models.ChannelName
import br.com.engapp.websocket_manager.models.MethodName
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class WebsocketManagerPlugin : FlutterPlugin {

    private var methodChannel: MethodChannel? = null
    private var messageChannel: EventChannel? = null
    private var doneChannel: EventChannel? = null

    private val messageStreamHandler =
        EventStreamHandler(this::onListenMessageCallback, this::onCancelCallback)

    private val closeStreamHandler =
        EventStreamHandler(this::onListenCloseCallback, this::onCancelCallback)

    private val websocketManager = StreamWebSocketManager()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        setupChannels(binding.binaryMessenger, binding.applicationContext)
        setupCallbacks()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        teardownChannels()
        websocketManager.disconnect()
    }

    private fun setupChannels(messenger: BinaryMessenger, context: Context) {
        methodChannel = MethodChannel(messenger, ChannelName.PLUGIN_NAME)
        methodChannel!!.setMethodCallHandler { call, result -> handleMethodCall(call, result) }

        messageChannel = EventChannel(messenger, ChannelName.MESSAGE)
        messageChannel!!.setStreamHandler(messageStreamHandler)

        doneChannel = EventChannel(messenger, ChannelName.DONE)
        doneChannel!!.setStreamHandler(closeStreamHandler)
    }

    private fun teardownChannels() {
        methodChannel?.setMethodCallHandler(null)
        messageChannel?.setStreamHandler(null)
        doneChannel?.setStreamHandler(null)

        methodChannel = null
        messageChannel = null
        doneChannel = null
    }

    private fun setupCallbacks() {
        websocketManager.messageCallback = { msg -> messageStreamHandler.send(msg) }
        websocketManager.closeCallback = { msg -> closeStreamHandler.send(msg) }
    }

    private fun handleMethodCall(call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MethodName.PLATFORM_VERSION -> result.success("Android ${android.os.Build.VERSION.RELEASE}")

            MethodName.CREATE -> {
                val url: String = call.argument("url")!!
                val header: Map<String, String>? = call.argument("header")
                websocketManager.create(url, header)
                result.success("")
            }

            MethodName.CONNECT -> {
                websocketManager.connect()
                result.success("")
            }

            MethodName.DISCONNECT -> {
                websocketManager.disconnect()
                result.success("")
            }

            MethodName.SEND_MESSAGE -> {
                val message: String = call.arguments()!!
                websocketManager.send(message)
                result.success("")
            }

            MethodName.AUTO_RETRY -> {
                val retry: Boolean = call.arguments<Boolean?>() ?: true
                websocketManager.enableRetries = retry
                result.success("")
            }

            MethodName.ON_MESSAGE -> result.success("") // already handled via callback

            MethodName.ON_DONE -> result.success("") // already handled via callback

            MethodName.TEST_ECHO -> {
                websocketManager.echoTest()
                result.success("echo test started")
            }

            else -> result.notImplemented()
        }
    }

    private fun onListenMessageCallback() {
        methodChannel?.invokeMethod(MethodName.LISTEN_MESSAGE, null)
    }

    private fun onListenCloseCallback() {
        methodChannel?.invokeMethod(MethodName.LISTEN_CLOSE, null)
    }

    private fun onCancelCallback() {
        // no-op
    }
}
