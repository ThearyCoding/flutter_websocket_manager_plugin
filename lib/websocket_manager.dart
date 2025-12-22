import 'dart:async';
import 'package:flutter/services.dart';

const String _PLUGIN_NAME = 'websocket_manager';
const String _EVENT_CHANNEL_MESSAGE = 'websocket_manager/message';
const String _EVENT_CHANNEL_DONE = '$_PLUGIN_NAME/done';
const String _METHOD_CHANNEL_CREATE = 'create';
const String _METHOD_CHANNEL_CONNECT = 'connect';
const String _METHOD_CHANNEL_DISCONNECT = 'disconnect';
const String _METHOD_CHANNEL_ON_MESSAGE = 'onMessage';
const String _METHOD_CHANNEL_ON_DONE = 'onDone';
const String _METHOD_CHANNEL_SEND = 'send';
const String _METHOD_CHANNEL_TEST_ECHO = 'echoTest';

/// Provides an easy way to create native websocket connection.
class WebsocketManager {
  WebsocketManager(this.url, [this.header]) {
    _create();
  }

  final String url;

  /// Optional headers passed to native platform.
  final Map<String, String>? header;

  static const MethodChannel _channel = MethodChannel(_PLUGIN_NAME);
  static const EventChannel _eventChannelMessage =
      EventChannel(_EVENT_CHANNEL_MESSAGE);
  static const EventChannel _eventChannelClose =
      EventChannel(_EVENT_CHANNEL_DONE);

  // nullable for null-safety
  static StreamSubscription<dynamic>? _onMessageSubscription;
  static StreamSubscription<dynamic>? _onCloseSubscription;
  static Stream<dynamic>? _eventsMessage;
  static Stream<dynamic>? _eventsClose;
  static void Function(dynamic)? _messageCallback;
  static void Function(dynamic)? _closeCallback;

  static Future<void> echoTest() async {
    final result = await _channel.invokeMethod(_METHOD_CHANNEL_TEST_ECHO);
    // ignore: avoid_print
    print(result);
  }

  Future<void> _create() async {
    // must return a Future
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'listen/message':
          _onMessage();
          break;
        case 'listen/close':
          _onClose();
          break;
      }
      return;
    });

    await _channel.invokeMethod(_METHOD_CHANNEL_CREATE, <String, dynamic>{
      'url': url,
      'header': header, // can be null
    });

    _onMessage();
    _onClose();
  }

  /// Creates a new WebSocket connection after instantiated [WebsocketManager].
  Future<void> connect() async {
    _onMessage();
    await _channel.invokeMethod(_METHOD_CHANNEL_CONNECT);
  }

  /// Closes the web socket connection.
  Future<void> close() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_DISCONNECT);

    // message stream
    _eventsMessage = null;
    await _onMessageSubscription?.cancel();
    _onMessageSubscription = null;
    _eventsClose = null;
    await _onCloseSubscription?.cancel();
    _onCloseSubscription = null;
  }

  /// Send a [String] message to the connected WebSocket.
  Future<void> send(String message) async {
    await _channel.invokeMethod(_METHOD_CHANNEL_SEND, message);
  }

  /// Adds a callback handler to this WebSocket sent data.
  void onMessage(void Function(dynamic) callback) {
    _messageCallback = callback;
    _startMessageServices().then((_) => _onMessage());
  }

  /// Adds a callback handler to this WebSocket close event.
  void onClose(void Function(dynamic) callback) {
    _closeCallback = callback;
    _startCloseServices().then((_) => _onClose());
  }

  Future<void> _startMessageServices() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_ON_MESSAGE);
  }

  void _onMessage() {
    if (_eventsMessage == null) {
      _eventsMessage =
          _eventChannelMessage.receiveBroadcastStream().asBroadcastStream();
      _onMessageSubscription = _eventsMessage!.listen(_messageListener);
    }
  }

  Future<void> _startCloseServices() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_ON_DONE);
  }

  void _onClose() {
    if (_eventsClose == null) {
      _eventsClose = _eventChannelClose.receiveBroadcastStream();
      _onCloseSubscription = _eventsClose!.listen(_closeListener);
    }
  }

  void _messageListener(dynamic message) {
    _messageCallback?.call(message);
  }

  void _closeListener(dynamic message) {
    // ignore: avoid_print
    print(message);
    _closeCallback?.call(message);
  }
}
