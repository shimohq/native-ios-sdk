//
//  SHMWebViewController.h
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

#import "SHMWebView.h"

NS_ASSUME_NONNULL_BEGIN

@interface SHMWebViewController : UIViewController

@property (nullable, nonatomic, strong, readonly) NSURL *url;
@property (nullable, nonatomic, copy, readonly) NSString *host;
@property (nullable, nonatomic, strong, readonly) SHMWebView *webview;

- (instancetype)initWithWebView:(SHMWebView *)webview;
- (instancetype)initWithUrl:(NSURL *)url host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
