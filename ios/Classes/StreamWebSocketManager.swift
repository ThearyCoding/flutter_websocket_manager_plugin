//
//  StreamManager.swift
//  websocket_manager
//
//  Created by Luan Almeida on 15/11/19.
//

import Starscream
@available(iOS 9.0, *)
class StreamWebSocketManager: NSObject, WebSocketDelegate {
    var ws: WebSocket?
    var updatesEnabled = false

    var messageCallback: ((_ data: String) -> Void)?
    var closeCallback: ((_ data: String) -> Void)?
    var conectedCallback: ((_ data: Bool) -> Void)?

    var enableRetries: Bool = true
    private var reconnectAttempts = 0
    private let maxReconnectDelay: TimeInterval = 30
    private var isManuallyClosed = false

    override init() {
        super.init()
    }

    func create(url: String, header: [String: String]?, enableCompression _: Bool?, disableSSL _: Bool?, enableRetries: Bool) {
        self.enableRetries = enableRetries
        isManuallyClosed = false
        reconnectAttempts = 0

        var request = URLRequest(url: URL(string: url)!)
        if let header = header {
            for (key, value) in header {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

        ws = WebSocket(request: request)
        ws?.delegate = self

        onConnect()
        onText()
        onClose()
    }

    func connect() {
        guard let socket = ws else { return }
        onText()
        socket.connect()
    }

    func disconnect() {
        isManuallyClosed = true
        enableRetries = false
        ws?.disconnect()
    }

    func send(string: String) {
        ws?.write(string: string)
    }

    func onText() {
        ws?.onText = { [weak self] text in
            self?.messageCallback?(text)
        }
    }

    func onConnect() {
        ws?.onConnect = { [weak self] in
            guard let self = self else { return }
            self.reconnectAttempts = 0 // reset attempts
            self.conectedCallback?(true)
        }
    }

    func onClose() {
        ws?.onDisconnect = { [weak self] error in
            guard let self = self else { return }
            self.conectedCallback?(false)
            self.closeCallback?(error != nil ? "false" : "true")

            if self.enableRetries && !self.isManuallyClosed {
                self.reconnectWithDelay()
            }
        }
    }

    private func reconnectWithDelay() {
        reconnectAttempts += 1
        let delay = min(pow(2.0, Double(reconnectAttempts)), maxReconnectDelay)
        print("WebSocket reconnecting in \(delay) seconds...")
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.connect()
        }
    }

    func isConnected() -> Bool {
        return ws?.isConnected ?? false
    }

    func echoTest() {
        var messageNum = 0
        ws = WebSocket(url: URL(string: "wss://echo.websocket.org")!)
        ws?.delegate = self
        let send: () -> Void = {
            messageNum += 1
            let msg = "\(messageNum): \(NSDate().description)"
            self.ws?.write(string: msg)
        }
        ws?.onConnect = { send() }
        ws?.onText = { _ in
            if messageNum == 10 {
                self.ws?.disconnect()
            } else { send() }
        }
        ws?.connect()
    }

 func websocketDidConnect(socket _: WebSocketClient) {
        //
    }

    func websocketDidDisconnect(socket _: WebSocketClient, error _: Error?) {
        //
    }

    func websocketDidReceiveMessage(socket _: WebSocketClient, text _: String) {
        //
    }

    func websocketDidReceiveData(socket _: WebSocketClient, data _: Data) {
        //
    }
}
