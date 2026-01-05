## 1.0.3 [2026-01-03]

### Added
- Added `onError()` support on the Flutter side:
  - New error EventChannel: `websocket_manager/error`
  - New method hook: `onError` with native error stream registration
  - Proper error stream cleanup during `close()`

### Fixed
- Added WebSocket keep-alive support via OkHttp `pingInterval` (15s) to prevent random disconnects and `EOFException` on production networks and proxies.
- Prevented duplicate WebSocket connections by tracking connection state (DISCONNECTED / CONNECTING / CONNECTED).
- Improved reconnect stability by clearing `ws` and connection state in `onClosed` / `onFailure` before scheduling a reconnect.
- Improved disconnect reliability by calling `cancel()` after `close()` to handle already-broken sockets correctly.

### Improved
- More accurate `isConnected()` result based on internal connection state instead of `ws != null`.
- Better error message reporting, including HTTP response code and message when available.
- Cleaner reconnect scheduling to avoid duplicate reconnect attempts while already connecting or connected.


## 1.0.2 [2026-01-03]

### Added
- Automatic reconnection with retry logic when the connection fails or drops.

### Changed
- Renamed main library file to match the package name (`flutter_websocket_manager_plugin.dart`).

### Improved
- Minor internal improvements and cleanup for initial publication.


## 1.0.1 [2025-12-22]

### Fixed
- iOS: Renamed podspec to `flutter_websocket_manager_plugin.podspec`.
- iOS: Adjusted `WebsocketManagerPlugin.m` imports and registration.
- Removed obsolete `websocket_manager.podspec`.
- Lockfile updates.


## 1.0.0 [2025-12-22]

### Changed
- Package maintenance taken over by **ThearyCoding**.
- Updated repository, homepage, and issue tracker links.
- Updated example project to match the new package name.
- Documentation and README updates.

> No breaking API changes from previous versions.


## 0.2.2 [2020-02-28]
- Migrated to the new Android embedding.
- Bumped Flutter SDK to `1.12.13+hotfix.5` or greater.


## 0.2.0 [2019-12-12]
- Updated OkHttp plugin.
- Fixed Android failure event that was not handled correctly.


## 0.1.3 [2019-12-12]
- Fixed bug where the close event channel was closed before sending the close event.


## 0.1.2 [2019-12-12]
- Ensured Flutter is notified even when there are no listeners on an event channel.


## 0.1.1 [2019-12-12]
- Fixed Android bug where `disconnect()` always triggered a reconnect due to retry logic.


## 0.1.0 [2019-12-09]
- Fixed bug when listening to event channels.
- Fixed iOS bug where `disconnect()` always reconnected due to retry logic.


## 0.0.2 [2019-12-03]
- Added comments, analysis file, and applied health suggestions.


## 0.0.1 [2019-12-02]
- Initial release.
