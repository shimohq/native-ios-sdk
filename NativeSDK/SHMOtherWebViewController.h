//
//  SHMOtherWebViewController.h
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/23.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 非 SHMWebView 的 WebViewController
@interface SHMOtherWebViewController : UIViewController

@property (nonnull, nonatomic, strong) NSURL *url;
@property (nullable, nonatomic, strong) WKWebView *webview;

@end

NS_ASSUME_NONNULL_END
