import 'dart:async';
import 'package:flutter/services.dart';

const String _PLUGIN_NAME = 'websocket_manager';

const String _EVENT_CHANNEL_MESSAGE = 'websocket_manager/message';
const String _EVENT_CHANNEL_DONE = '$_PLUGIN_NAME/done';
const String _EVENT_CHANNEL_ERROR = 'websocket_manager/error';

const String _METHOD_CHANNEL_CREATE = 'create';
const String _METHOD_CHANNEL_CONNECT = 'connect';
const String _METHOD_CHANNEL_DISCONNECT = 'disconnect';
const String _METHOD_CHANNEL_ON_MESSAGE = 'onMessage';
const String _METHOD_CHANNEL_ON_DONE = 'onDone';
const String _METHOD_CHANNEL_ON_ERROR = 'onError';
const String _METHOD_CHANNEL_SEND = 'send';
const String _METHOD_CHANNEL_TEST_ECHO = 'echoTest';

/// Provides an easy way to create native websocket connection.
class WebsocketManager {
  WebsocketManager(
    this.url, [
    this.header,
    this.autoReconnect = true,
  ]) {
    _create();
  }

  final String url;
  final bool autoReconnect;

  /// Optional headers passed to native platform.
  final Map<String, String>? header;

  static const MethodChannel _channel = MethodChannel(_PLUGIN_NAME);

  static const EventChannel _eventChannelMessage =
      EventChannel(_EVENT_CHANNEL_MESSAGE);
  static const EventChannel _eventChannelClose = EventChannel(_EVENT_CHANNEL_DONE);
  static const EventChannel _eventChannelError = EventChannel(_EVENT_CHANNEL_ERROR);

  // message
  static StreamSubscription<dynamic>? _onMessageSubscription;
  static Stream<dynamic>? _eventsMessage;
  static void Function(dynamic)? _messageCallback;

  // close
  static StreamSubscription<dynamic>? _onCloseSubscription;
  static Stream<dynamic>? _eventsClose;
  static void Function(dynamic)? _closeCallback;

  // error
  static StreamSubscription<dynamic>? _onErrorSubscription;
  static Stream<dynamic>? _eventsError;
  static void Function(dynamic)? _errorCallback;

  Future<void> echoTest() async {
    final result = await _channel.invokeMethod(_METHOD_CHANNEL_TEST_ECHO);
    // ignore: avoid_print
    print(result);
  }

  Future<void> _create() async {
    _channel.setMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'listen/message':
          _onMessage();
          break;
        case 'listen/close':
          _onClose();
          break;
        case 'listen/error':
          _onError();
          break;
      }
      return null;
    });

    await _channel.invokeMethod(_METHOD_CHANNEL_CREATE, <String, dynamic>{
      'url': url,
      'header': header,
      'enableRetries': autoReconnect,
    });

    await _enableAutoReconnect();

    // only start streams that have callbacks registered
    // (or keep these if you prefer always-listen)
    _onMessage();
    _onClose();
    _onError();
  }

  Future<void> _enableAutoReconnect() async {
    await _channel.invokeMethod('autoRetry', autoReconnect);
  }

  /// Creates a new WebSocket connection after instantiated [WebsocketManager].
  Future<void> connect() async {
    _onMessage();
    _onClose();
    _onError();
    await _channel.invokeMethod(_METHOD_CHANNEL_CONNECT);
  }

  /// Closes the web socket connection.
  Future<void> close() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_DISCONNECT);

    // message stream cleanup
    _eventsMessage = null;
    await _onMessageSubscription?.cancel();
    _onMessageSubscription = null;

    // close stream cleanup
    _eventsClose = null;
    await _onCloseSubscription?.cancel();
    _onCloseSubscription = null;

    // error stream cleanup
    _eventsError = null;
    await _onErrorSubscription?.cancel();
    _onErrorSubscription = null;
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

  /// Adds a callback handler to this WebSocket error event.
  void onError(void Function(dynamic) callback) {
    _errorCallback = callback;
    _startErrorServices().then((_) => _onError());
  }

  Future<void> _startMessageServices() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_ON_MESSAGE);
  }

  Future<void> _startCloseServices() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_ON_DONE);
  }

  Future<void> _startErrorServices() async {
    await _channel.invokeMethod(_METHOD_CHANNEL_ON_ERROR);
  }

  void _onMessage() {
    if (_eventsMessage == null) {
      _eventsMessage =
          _eventChannelMessage.receiveBroadcastStream().asBroadcastStream();
      _onMessageSubscription = _eventsMessage!.listen(_messageListener);
    }
  }

  void _onClose() {
    if (_eventsClose == null) {
      _eventsClose = _eventChannelClose.receiveBroadcastStream().asBroadcastStream();
      _onCloseSubscription = _eventsClose!.listen(_closeListener);
    }
  }

  void _onError() {
    if (_eventsError == null) {
      _eventsError =
          _eventChannelError.receiveBroadcastStream().asBroadcastStream();
      _onErrorSubscription = _eventsError!.listen(_errorListener);
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

  void _errorListener(dynamic error) {
    _errorCallback?.call(error);
  }
}
