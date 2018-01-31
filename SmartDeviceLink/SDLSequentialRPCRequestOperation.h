//
//  SDLSequentialRPCRequestOperation.h
//  SmartDeviceLink
//
//  Created by Joel Fischer on 1/31/18.
//  Copyright © 2018 smartdevicelink. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SDLAsynchronousOperation.h"
#import "SDLLifecycleManager.h"

@protocol SDLConnectionManagerType;

@interface SDLSequentialRPCRequestOperation : SDLAsynchronousOperation

- (instancetype)initWithConnectionManager:(id<SDLConnectionManagerType>)connectionManager requests:(NSArray<SDLRPCRequest *> *)requests progressHandler:(nullable SDLMultipleRequestProgressHandler)progressHandler completionHandler:(nullable SDLMultipleRequestCompletionHandler)completionHandler;

@end
