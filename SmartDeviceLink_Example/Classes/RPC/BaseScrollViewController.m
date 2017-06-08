//
//  BaseScrollViewController.m
//  SmartDeviceLink-iOS

#import "BaseScrollViewController.h"

@interface BaseScrollViewController ()

@end

@implementation BaseScrollViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.frame = self.view.bounds;
    scrollView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:scrollView];
    _scrollView = scrollView;
    
    _contentView = [[UIView alloc] init];
    _contentView.frame = scrollView.bounds;
    [scrollView addSubview:_contentView];
    
    [self showUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)showUI {
    
}

@end
