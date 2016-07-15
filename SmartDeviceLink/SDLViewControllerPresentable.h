//
//  SDLDialogPresenting.h
//  SmartDeviceLink-iOS
//
//  Created by Joel Fischer on 7/15/16.
//  Copyright © 2016 smartdevicelink. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SDLViewControllerPresentable <NSObject>

+ (void)presentViewController:(UIViewController *)viewController;

@end
