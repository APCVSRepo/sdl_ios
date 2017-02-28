//
//  SDLLogTargetFile.m
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 2/28/17.
//  Copyright © 2017 smartdevicelink. All rights reserved.
//

#import "SDLLogTargetFile.h"

#import "SDLLogModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface SDLLogTargetFile ()

@property (assign, nonatomic) NSUInteger maxFiles;
@property (strong, nonatomic, nullable) NSFileHandle *logFileHandle;

@end


@implementation SDLLogTargetFile

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    _maxFiles = 3;

    return self;
}

+ (id<SDLLogTarget>)logger {
    return [[self alloc] init];
}

- (BOOL)setupLogger {
    return YES;
}

- (void)logWithLog:(SDLLogModel *)log formattedLog:(NSString *)stringLog {
    NSData *logData = [stringLog dataUsingEncoding:NSUTF8StringEncoding];

    NSInteger writtenBytes = write(STDERR_FILENO, logData.bytes, logData.length);
    if (writtenBytes < 0) {
        // Something went wrong
    }
}

- (void)teardownLogger {}

@end

NS_ASSUME_NONNULL_END
