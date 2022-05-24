//
//  SHMOtherWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/23.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMOtherWebViewController.h"
#import "SHMDownloadViewController.h"

#import <Masonry/Masonry.h>

@interface SHMOtherWebViewController () <WKNavigationDelegate, WKUIDelegate>

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
    self.webview.navigationDelegate = self;
    [self.view addSubview:self.webview];
    [self.webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
    [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler WK_SWIFT_ASYNC(3) {
    NSURL *url = navigationAction.request.URL;
    NSLog(@"SHMOtherWebViewController: decidePolicyForNavigationAction: %@", url.absoluteString);
    NSLog(@"SHMOtherWebViewController: navigationType: %ld", navigationAction.navigationType);
    decisionHandler(WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler WK_SWIFT_ASYNC(3) {
    NSURLResponse *response = navigationResponse.response;
    NSLog(@"SHMOtherWebViewController: decidePolicyForNavigationResponse: %@", webView.URL.absoluteString);
    NSLog(@"SHMOtherWebViewController: canShowMIMEType: %d", navigationResponse.canShowMIMEType);
    NSLog(@"SHMOtherWebViewController: response.MIMEType: %@", response.MIMEType);
    NSLog(@"SHMOtherWebViewController: response.URL: %@", response.URL);
    NSLog(@"SHMOtherWebViewController: response.suggestedFilename: %@", response.suggestedFilename);
    NSLog(@"SHMOtherWebViewController: response.textEncodingName: %@", response.textEncodingName);
    if (navigationResponse.canShowMIMEType
        && response.URL
        && response.MIMEType
        && ![@"text/html" isEqualToString:response.MIMEType]) {
        // TODO MIME type 可以获取，且值不是 text/html，下载文件
        SHMDownloadViewController *viewController = [[SHMDownloadViewController alloc] init];
        viewController.response = response;
        
        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
        [viewControllers removeLastObject];
        [viewControllers addObject:viewController];
        [self.navigationController setViewControllers:viewControllers animated:NO];
        decisionHandler(WKNavigationResponsePolicyCancel);
        return;
    }
    decisionHandler(WKNavigationResponsePolicyAllow);
}

@end
