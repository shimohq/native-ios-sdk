//
//  SHMOtherWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/23.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMOtherWebViewController.h"

#import <Masonry/Masonry.h>

@interface SHMOtherWebViewController ()

@end

@implementation SHMOtherWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    if (self.webview) {
        if (self.webview.superview) {
            [self.webview removeFromSuperview];
        }
    } else {
        self.webview = [[WKWebView alloc] initWithFrame:self.view.bounds];
    }
    [self.view addSubview:self.webview];
    [self.webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
    [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

@end
