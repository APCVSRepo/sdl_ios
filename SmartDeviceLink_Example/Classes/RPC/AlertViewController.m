//
//  AlertViewController.m
//  SmartDeviceLink-iOS

#import "AlertViewController.h"

#import "SDLAlert.h"

@interface AlertViewController ()
{
    UITextField *_alertText1;
    UITextField *_alertText2;
    UITextField *_duration;
}
@end

@implementation AlertViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showUI {
    NSArray *array = @[@"alertText1", @"alertText1"];
    for (NSInteger i = 0; i < array.count; i++) {
        UILabel *keyLabel = [[UILabel alloc] init];
        keyLabel.frame = CGRectMake(0, 100 + (30 + 20) * i, 100, 30);
        keyLabel.textAlignment = NSTextAlignmentRight;
        keyLabel.text = [array objectAtIndex:i];
        [_contentView addSubview:keyLabel];
        
        UITextField *textField = [[UITextField alloc] init];
        textField.frame = CGRectMake(CGRectGetMaxX(keyLabel.frame) + 20, CGRectGetMinY(keyLabel.frame), CGRectGetWidth(self.view.frame) - CGRectGetMaxX(keyLabel.frame) - 20 - 20, CGRectGetHeight(keyLabel.frame));
        textField.borderStyle = UITextBorderStyleRoundedRect;
        textField.delegate = self;
        [_contentView addSubview:textField];
        
        switch (i) {
            case 0: {
                _alertText1 = textField;
                break;
            }
                
            case 1: {
                _alertText2 = textField;
                break;
            }
                
            case 2: {
                _duration = textField;
                _duration.keyboardType = UIKeyboardTypeNumberPad;
                break;
            }
                
            default:
                break;
        }
    }
}

- (void)submitRPC {
    NSString *alertText1 = _alertText1.text;
    NSString *alertText2 = _alertText2.text;
    NSString *duration = @"5000";
    
    [self.view endEditing:YES];
    
    SDLAlert *alert = [[SDLAlert alloc] initWithAlertText1:alertText1 alertText2:alertText2 duration:[duration integerValue]];
    alert.playTone = @(YES);
    alert.correlationID = @(102);
    [[ProxyManager sharedManager].sdlManager.proxy sendRPC:alert];
}

@end
