//
//  SDLConnectionManager.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 10/21/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDLNotificationConstants.h"

@class SDLRPCRequest;


NS_ASSUME_NONNULL_BEGIN

// TODO: May want to rename
@protocol SDLConnectionManager <NSObject>

- (void)sendRequest:(SDLRPCRequest *)request withCompletionHandler:(nullable SDLRequestCompletionHandler)block;

@end

NS_ASSUME_NONNULL_END
