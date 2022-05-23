//
//  SHMOtherWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/23.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMOtherWebViewController.h"

@interface SHMOtherWebViewController ()

@end

@implementation SHMOtherWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (!self.webview) {
        self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    } else {
        self.webview.frame = self.view.bounds;
    }
    self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    UIView *superview = self.webview.superview;
    if (superview) {
        [self.webview removeFromSuperview];
    }
    [self.view addSubview:self.webview];
    
    [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

@end
