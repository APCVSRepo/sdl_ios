//
//  BaseScrollViewController.h
//  SmartDeviceLink-iOS

#import "BaseViewController.h"

#import "ProxyManager.h"
#import "SDLTextAlignment.h"
#import "SDLProxy.h"

@interface BaseScrollViewController : BaseViewController
{
    UIScrollView *_scrollView;
    UIView *_contentView;
}

@end
