package br.com.engapp.websocket_manager

import br.com.engapp.websocket_manager.models.MethodName
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WebSocketMethodChannelHandler(
    private val messageStreamHandler: EventStreamHandler,
    private val closeStreamHandler: EventStreamHandler
) : MethodChannel.MethodCallHandler {

    private val websocketManager = StreamWebSocketManager()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            MethodName.PLATFORM_VERSION -> result.success("Android ${android.os.Build.VERSION.RELEASE}")

            MethodName.CREATE -> {
                val url: String? = call.argument("url")
                val header: Map<String, String>? = call.argument("header")

                websocketManager.create(url!!, header)

                websocketManager.messageCallback = { msg ->
                    messageStreamHandler.send(msg)
                }
                websocketManager.closeCallback = { msg ->
                    closeStreamHandler.send(msg)
                }
                result.success("")
            }

            MethodName.CONNECT -> { websocketManager.connect(); result.success("") }
            MethodName.DISCONNECT -> { websocketManager.disconnect(); result.success("") }

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

            MethodName.ON_MESSAGE -> {
                websocketManager.messageCallback = { msg -> messageStreamHandler.send(msg) }
                result.success("")
            }

            MethodName.ON_DONE -> {
                websocketManager.closeCallback = { msg -> closeStreamHandler.send(msg) }
                result.success("")
            }

            MethodName.TEST_ECHO -> { websocketManager.echoTest(); result.success("echo test") }

            else -> result.notImplemented()
        }
    }
}
