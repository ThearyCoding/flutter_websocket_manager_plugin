#import "WebsocketManagerPlugin.h"

#if __has_include(<flutter_websocket_manager_plugin/flutter_websocket_manager_plugin-Swift.h>)
#import <flutter_websocket_manager_plugin/flutter_websocket_manager_plugin-Swift.h>
#else
#import "flutter_websocket_manager_plugin-Swift.h"
#endif

@implementation WebsocketManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftWebsocketManagerPlugin registerWithRegistrar:registrar];
}
@end
