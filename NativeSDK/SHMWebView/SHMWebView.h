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

/// 打开 URL 的方式
typedef NS_ENUM(NSUInteger, SHMWebViewNavigateMethod) {
    // 新窗口使用 SHMWebView 打开，常用于打开文件和 window.open 方式打开任何信任 host 链接
    SHMWebViewNavigateMethodNewWebView,
    // 外部浏览器打开，常用于非信任 host 链接
    SHMWebViewNavigateMethodExternal
};


@class SHMWebView;

@protocol SHMWebViewDelegate <NSObject>

/// 在非当前 SHMWebView 打开 URL
/// @param webview SHMWebView 实例
/// @param url 将要打开的 URL
/// @param method 打开 URL 的方式
- (void)webview:(nonnull SHMWebView *)webview navigateToUrl:(nullable NSURL *)url withMethod:(SHMWebViewNavigateMethod)method;

/// window.open 方式打开 URL
/// @param webview SHMWebView 实例
/// @param method 打开 URL 的方式
/// @return 将要打开 url 的 WKWebView 实例，返回 nil 将不会跳转
- (nullable WKWebView *)webview:(nonnull SHMWebView *)webview
           windowOpenWithMethod:(SHMWebViewNavigateMethod)method
                  configuration:(nonnull WKWebViewConfiguration *)configuration
            forNavigationAction:(nonnull WKNavigationAction *)navigationAction
                 windowFeatures:(nonnull WKWindowFeatures *)windowFeatures;

/// 设置标题
///
/// @param webview SHMWebView 实例
/// @param title 标题，为 nil 时表示 WebView 没有设置标题，使用自定义的默认标题
- (void)webview:(nonnull SHMWebView *)webview setNavigatorTitle:(nullable NSString *)title;

/// 设置导航条按钮
///
/// 每次回调都用覆盖的方式更新导航条按钮。
/// @param webview SHMWebView 实例
/// @param buttons 按钮数据
- (void)webview:(nonnull SHMWebView *)webview setNavigatorButtons:(nonnull NSArray<SHMWebViewNavigatorButton *> *)buttons;

@optional

/// 设置返回按钮是否可用
///
/// 如果返回按钮常驻就不需要实现该代理
/// @param webview SHMWebView 实例
/// @param backButtonEnabled 返回按钮是否可用。
/// YES: 返回按钮可用，点击返回按钮会触发 WebView 的返回事件。
/// NO: 返回按钮不可用，点击返回按钮不会触发 WebView 的返回事件
- (void)webview:(nonnull SHMWebView *)webview setBackButtonEnabled:(BOOL)backButtonEnabled;

/// 监听文件下载
///
/// 当 url 请求返回的 MIME type 不是 text/html 时，该请求当下载处理。如果不实现该方法，将直接在 WebView 打开。
/// @param webview SHMWebView 实例
/// @param response url fileName MIMEType 等信息
/// @param inNewWindow 是否是在新窗口打开的下载，如果是的打开下载界面时要关闭当前窗口
- (void)webview:(nonnull SHMWebView *)webview downloadWithResponse:(nonnull NSURLResponse *)response inNewWindow:(BOOL)inNewWindow;

@end

@interface SHMWebView : UIView

/// 将要加载的 URL
@property (nonnull, nonatomic, strong) NSURL *url;

/// WebView 内打开的链接域名白名单
///
/// 为 nil 时，不拦截外部链接，外部链接可以直接在当前 WebView 内打开。
@property (nullable, nonatomic, copy) NSArray<NSString *> *hosts;

/// 当前 App 的 ID
///
/// Default: NativeSDK-1
@property (nonnull, nonatomic, copy) NSString *appID;

/// 当前 App 语言
///
/// Default: zh-CN
@property (nonnull, nonatomic, copy) NSString *lang;

/// 当前 App 布局方向
///
/// Default: ltr
@property (nonnull, nonatomic, copy) NSString *dir;

/// WebView 配置
///
/// 一般情况不需要赋值，会自动创建新的
@property (nullable, nonatomic, copy) WKWebViewConfiguration *configuration;

/// 使用 SHMWebView 需要实现的代理
@property (nullable, nonatomic, weak) id<SHMWebViewDelegate> delegate;

/// 自定义 WKWebView 的 WKNavigationDelegate
///
/// 可自定义跳转拦截
/// 默认效果不满足要求时才需要配置
@property (nullable, nonatomic, weak) id <WKNavigationDelegate> navigationDelegate;

/// 自定义 WKWebView 的 WKUIDelegate
///
/// 可自定义 alert、confirm、promit 和拦截新窗口打开时用
/// 默认效果不满足要求时才需要配置
@property (nullable, nonatomic, weak) id <WKUIDelegate> UIDelegate;

/// 返回按钮是否可用
///
/// 默认: NO
@property (nonatomic, assign, readonly) BOOL backButtonEnabled;

/// WKWebView 实例
///
/// didMoveToWindow 的时候自动创建，
/// 尽量不要直接操作 webview，因为无法保证 webview 是否已经创建好。
@property (nonnull, nonatomic, strong, readonly) WKWebView *webview;


/// 获取 SHMWebView 所在的 UIViewController
@property (nullable, nonatomic, strong, readonly) UIViewController *viewController;

/// 创建并添加 WKWebView 到 SHMWebView
///
/// didMoveToWindow 的时候会自动调用，一般情况不需要主动调用该方法，
/// 除非需要在所有属性配置好后立即获取 WKWebView。
- (nonnull WKWebView *)createAndSetWebView;

/// 用户点击原生返回按钮时，调用该方法判断是否执行原生返回。
///
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
