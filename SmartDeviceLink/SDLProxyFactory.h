//  SDLProxyFactory.h
//

#import <Foundation/Foundation.h>

#import "SDLProxyListener.h"

@class SDLProxy;

NS_ASSUME_NONNULL_BEGIN

__deprecated_msg("Use SDLManager instead")
@interface SDLProxyFactory : NSObject {
}

+ (SDLProxy *)buildSDLProxyWithiAPListener:(NSObject<SDLProxyListener> *)listener;

+ (SDLProxy *)buildSDLProxyWithTCPListener:(NSObject<SDLProxyListener> *)listener
                              tcpIPAddress:(NSString *)ipaddress
                                   tcpPort:(NSString *)port;
@end

NS_ASSUME_NONNULL_END
