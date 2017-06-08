//
//  ShowViewController.m
//  SmartDeviceLink-iOS

#import "ShowViewController.h"

#import "SDLShow.h"

@interface ShowViewController ()
{
    UITextField *_mainField1;
    UISegmentedControl *_alignSegmentedControl;
}
@end

@implementation ShowViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showUI {
    NSArray *array = @[@"mainField1", @"alignment"];
    for (NSInteger i = 0; i < array.count; i++) {
        UILabel *keyLabel = [[UILabel alloc] init];
        keyLabel.frame = CGRectMake(0, 100 + (30 + 20) * i, 100, 30);
        keyLabel.textAlignment = NSTextAlignmentRight;
        keyLabel.text = [array objectAtIndex:i];
        [_contentView addSubview:keyLabel];
        
        if (i == 0) {
            _mainField1 = [[UITextField alloc] init];
            _mainField1.frame = CGRectMake(CGRectGetMaxX(keyLabel.frame) + 20, CGRectGetMinY(keyLabel.frame), CGRectGetWidth(self.view.frame) - CGRectGetMaxX(keyLabel.frame) - 20 - 20, CGRectGetHeight(keyLabel.frame));
            _mainField1.delegate = self;
            _mainField1.borderStyle = UITextBorderStyleRoundedRect;
            [_contentView addSubview:_mainField1];
        } else if (i == 1) {
            _alignSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"LEFT", @"CENTER", @"RIGHT"]];
            _alignSegmentedControl.frame = CGRectMake(CGRectGetMinX(_mainField1.frame), CGRectGetMinY(keyLabel.frame), CGRectGetWidth(_mainField1.frame), CGRectGetHeight(_mainField1.frame));
            _alignSegmentedControl.selectedSegmentIndex = 0;
            [_contentView addSubview:_alignSegmentedControl];
        }
    }
}

- (void)submitRPC {
    NSString *mainField1 = _mainField1.text;
    if (mainField1.length == 0) {
        return;
    }
    
    [self.view endEditing:YES];
    
    SDLTextAlignment *align;
    switch (_alignSegmentedControl.selectedSegmentIndex) {
        case 0:
            align = [SDLTextAlignment LEFT_ALIGNED];
            break;
            
        case 1:
            align = [SDLTextAlignment CENTERED];
            break;
            
        case 2:
            align = [SDLTextAlignment RIGHT_ALIGNED];
            break;
            
        default:
            break;
    }
    
    SDLShow *show = [[SDLShow alloc] init];
    show.mainField1 = mainField1;
    show.alignment = align;
    show.correlationID = @(101);
    [[ProxyManager sharedManager].sdlManager.proxy sendRPC:show];
}

@end
