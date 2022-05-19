//
//  SHMWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMWebViewController.h"

#import <WebKit/WebKit.h>
#import <Masonry/Masonry.h>
#import "SHMWebView.h"

@interface SHMWebViewController ()

@property (nonnull, nonatomic, strong) NSURL *url;

@end

@implementation SHMWebViewController

- (instancetype)initWithUrl:(nonnull NSURL *)url {
    self = [super init];
    if (self) {
        _url = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    WKWebView *webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
    
    [self.view addSubview:webview];
    [webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
    
    [webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

@end
