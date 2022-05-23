//
//  SHMWebView.h
//  WebView
//
//  Created by 陈阳 on 2022/5/18.
//
#import <WebKit/WebKit.h>
#import "SHMWebViewNavigatorButton.h"

#ifndef SHMWebView_h
#define SHMWebView_h

@class SHMWebView;

@protocol SHMWebViewDelegate <NSObject>

/// 设置标题
/// @param webview WebView 实例
/// @param title 标题，为 nil 时表示去掉 JS 设置的标题，还原默认标题
- (void)webview:(nonnull SHMWebView *)webview setNavigatorTitle:(nullable NSString *)title;

/// 根据约定的数据设置导航条按钮
/// @param webview WebView 实例
/// @param buttons 按钮数据
- (void)webview:(nonnull SHMWebView *)webview setNavigatorButtons:(nonnull NSArray<SHMWebViewNavigatorButton *> *)buttons;

@optional

/// 设置返回按钮是否可用
/// 如果返回按钮常驻就不需要实现该代理
/// @param webview WebView 实例
/// @param backButtonEnable 返回按钮是否可用。
/// YES: 返回按钮可用，点击返回按钮会触发 WebView 的返回事件
/// NO: 返回按钮不可用，点击返回按钮不会触发 WebView 的返回事件
- (void)webview:(nonnull SHMWebView *)webview setBackButtonEnable:(BOOL)backButtonEnable;

@end

@interface SHMWebView : UIView

/// 将要加载的 URL
@property (nonnull, nonatomic, strong) NSURL *url;

/// 当前石墨部署环境域名
@property (nonnull, nonatomic, copy) NSString *host;

/// WebView 配置
/// 一般情况不需要赋值，会自动创建新的
@property (nullable, nonatomic, copy) WKWebViewConfiguration *configuration;

/// WKWebView 默认 user agent 添加后缀
/// Default: @"SMWV/1.35  (HWMT-730; lang: zh-CN; dir: ltr)"
/// 根据实际情况填充 lang 和 dir 字段 
@property (nullable, nonatomic, copy) NSString *applicationNameForUserAgent;

/// 使用 SHMWebView 需要实现的代理
@property (nullable, nonatomic, weak) id<SHMWebViewDelegate> delegate;

/// WKWebView 的 WKNavigationDelegate
/// 拦截跳转时用
@property (nullable, nonatomic, weak) id <WKNavigationDelegate> navigationDelegate;

/// WKWebView 的 WKUIDelegate
/// 自定义 alert、confirm、promit 和拦截新窗口打开时用
@property (nullable, nonatomic, weak) id <WKUIDelegate> UIDelegate;

/// 返回按钮是否可用
/// 默认: NO
@property (nonatomic, assign, readonly) BOOL backButtonEnable;

/// didMoveToWindow 的时候自动创建
/// 尽量不要直接操作 webview，因为无法保证 webview 是否已经创建好。
@property (nonnull, nonatomic, strong, readonly) WKWebView *webview;

/// 创建并添加 WKWebView 到 SHMWebView
/// didMoveToWindow 的时候会自动调用，除非需要提前获取 WKWebView，否则不要调用该方法。
- (nonnull WKWebView *)createAndSetWebView;

/// 用户点击原生返回按钮时，调用该方法判断是否执行原生返回。
/// 返回值 nativeGoBack 为 YES 时执行的原生返回，为 NO 表示 Web 内已执行返回不需要原生返回。
/// @param callback JS 回调
- (void)goBackWithCallback:(void (^__nullable)(BOOL nativeGoBack))callback;

/// 导航条按钮点击
/// @param navigatorButton 导航按钮数据
- (void)clickNavigatorButton:(nonnull SHMWebViewNavigatorButton *)navigatorButton;

/// 是否为石墨文件链接
/// @param url 链接
+ (BOOL)isFileURL:(nonnull NSURL *)url;

@end

#endif /* SHMWebView_h */
