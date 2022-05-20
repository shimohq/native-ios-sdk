//
//  SHMWebView.h
//  WebView
//
//  Created by 陈阳 on 2022/5/18.
//
#import <WebKit/WebKit.h>

#ifndef SHMWebView_h
#define SHMWebView_h

@class SHMWebView;

@protocol SHMWebViewDelegate <NSObject>

/// 设置标题
/// @param webview WebView 实例
/// @param title 标题
- (void)webview:(nonnull SHMWebView *)webview setNavigatorTitle:(nonnull NSString *)title;

/// 根据 type 和约定的 payload 设置导航条按钮
/// @param webview WebView 实例
/// @param type 按钮类型
/// @param payload 按钮数据
- (void)webview:(nonnull SHMWebView *)webview setNavigatorButtonWithType:(nonnull NSString *)type payload:(nonnull NSString *)payload;

@end

@interface SHMWebView : UIView

/// 将要加载的 URL
@property (nonnull, nonatomic, strong) NSURL *url;

/// 当前石墨部署环境域名
@property (nonnull, nonatomic, copy) NSString *host;

/// userContentController 的名称
/// Default: _SMWV-UCC_
@property (nullable, nonatomic, copy) NSString *userContentControllerName;

/// 支持的 native 方法
/// Default: @[@"setNavigatorTitle", @"setNavigatorBack", @"setNavigatorButtons"]
@property (nonnull, nonatomic, copy) NSArray *supportedMethods;

/// 使用 SHMWebView 需要实现的代理
@property (nullable, nonatomic, weak) id<SHMWebViewDelegate> shmWebViewDelegate;

/// didMoveToWindow 的时候自动创建
@property (nonnull, nonatomic, strong, readonly) WKWebView *webview;

/// 用户点击原生返回按钮时，调用该方法，根据返回值 willGoBack 判断是否要执行的原生的返回
/// @param callback JS 回调
- (void)goBackWithCallback:(void (^__nullable)(BOOL willGoBack))callback;

/// 导航条按钮点击
/// @param type 按钮类型
/// @param payload 按钮数据
- (void)clickButtonWithType:(nonnull NSString *)type payload:(nonnull NSString *)payload;

/// 是否为石墨文件链接
/// @param url 链接
+ (BOOL)isFileURL:(nonnull NSURL *)url;

@end

#endif /* SHMWebView_h */
