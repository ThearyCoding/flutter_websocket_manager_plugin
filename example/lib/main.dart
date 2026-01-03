import 'package:flutter/material.dart';
import 'package:flutter_websocket_manager_plugin/flutter_websocket_plugin.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _urlController = TextEditingController(
    text: 'wss://ws.ifelse.io',
  );

  final TextEditingController _messageController = TextEditingController();

  WebsocketManager? socket;
  String _message = '';
  String _closeMessage = '';

  @override
  void dispose() {
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Websocket Manager Example'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'WebSocket URL',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        socket = WebsocketManager(_urlController.text);
                        _closeMessage = '';
                        _message = '';
                      });
                    },
                    child: const Text('CONFIG'),
                  ),
                  ElevatedButton(
                    onPressed: socket == null ? null : () => socket!.connect(),
                    child: const Text('CONNECT'),
                  ),
                  ElevatedButton(
                    onPressed: socket == null ? null : () => socket!.close(),
                    child: const Text('CLOSE'),
                  ),
                  ElevatedButton(
                    onPressed: socket == null
                        ? null
                        : () {
                            socket!.onMessage((dynamic message) {
                              // ignore: avoid_print
                              print('New message: $message');
                              if (!mounted) return;
                              setState(() {
                                _message = message.toString();
                              });
                            });
                          },
                    child: const Text('LISTEN MESSAGE'),
                  ),
                  ElevatedButton(
                    onPressed: socket == null
                        ? null
                        : () {
                            socket!.onClose((dynamic message) {
                              // ignore: avoid_print
                              print('Close message: $message');
                              if (!mounted) return;
                              setState(() {
                                _closeMessage = message.toString();
                              });
                            });
                          },
                    child: const Text('LISTEN DONE'),
                  ),
                  ElevatedButton(
                    onPressed: () => socket?.echoTest(),
                    child: const Text('ECHO TEST'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  labelText: 'Message',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: socket == null
                        ? null
                        : () {
                            socket!.send(_messageController.text);
                          },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Received message:'),
              Text(_message),
              const SizedBox(height: 8),
              const Text('Close message:'),
              Text(_closeMessage),
            ],
          ),
        ),
      ),
    );
  }
}
