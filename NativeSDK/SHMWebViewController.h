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


/// SHMWebView 的 WebViewController
@interface SHMWebViewController : UIViewController

@property (nonnull, nonatomic, strong) NSURL *url;
@property (nullable, nonatomic, copy) NSArray<NSString *> *origins;
@property (nullable, nonatomic, strong) SHMWebView *webview;
@property (nonatomic, assign, getter=isSubWebView) BOOL subWebView;

@end

NS_ASSUME_NONNULL_END
