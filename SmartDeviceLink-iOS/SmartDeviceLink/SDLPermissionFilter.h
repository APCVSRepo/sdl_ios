//
//  SDLPermissionFilter.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 11/18/15.
//  Copyright © 2015 smartdevicelink. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "SDLPermissionsConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface SDLPermissionFilter : NSObject <NSCopying>

@property (copy, nonatomic, readonly) SDLPermissionObserverIdentifier *identifier;
@property (copy, nonatomic, readonly) NSArray<SDLPermissionRPCName *> *rpcNames;
@property (assign, nonatomic, readonly) SDLPermissionChangeType changeType;
@property (copy, nonatomic, readonly) SDLPermissionObserver observer;

- (instancetype)initWithRPCNames:(NSArray<SDLPermissionRPCName *> *)rpcNames changeType:(SDLPermissionChangeType)changeType observer:(SDLPermissionObserver)observer NS_DESIGNATED_INITIALIZER;

+ (instancetype)filterWithRPCNames:(NSArray<SDLPermissionRPCName *> *)rpcNames changeType:(SDLPermissionChangeType)changeType observer:(SDLPermissionObserver)observer;

- (BOOL)isEqualToFilter:(SDLPermissionFilter *)otherFilter;

@end

NS_ASSUME_NONNULL_END
