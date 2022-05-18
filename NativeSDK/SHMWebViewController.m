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
    
    WKWebView *webview = [self createWebView];
    
    [self.view addSubview:webview];
    [webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
    
    [webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (WKWebView *)createWebView {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    config.selectionGranularity = WKSelectionGranularityDynamic;
    config.processPool = [[WKProcessPool alloc] init];
    config.websiteDataStore = [WKWebsiteDataStore defaultDataStore];
    @try {
        [config setValue:[NSNumber numberWithBool:YES] forKey:@"allowUniversalAccessFromFileURLs"];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    
    WKPreferences *preferences = [[WKPreferences alloc] init];
    @try {
        [preferences setValue:[NSNumber numberWithBool:YES] forKey:@"allowFileAccessFromFileURLs"];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
    config.preferences = preferences;
    
    WKWebView *webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:config];
    
    webView.opaque = webView.scrollView.opaque = NO;
    webView.backgroundColor = webView.scrollView.backgroundColor = [UIColor clearColor];
    
    return webView;
}

@end
