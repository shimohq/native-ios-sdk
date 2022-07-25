//
//  SHMWebView.m
//  WebView
//
//  Created by 陈阳 on 2022/5/18.
//

#import "SHMWebView.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/// 设置导航文字标题
NSString *const SHMWVContextMethodSetNavigatorTitle = @"setNavigatorTitle";

/// 设置导航返回按钮
NSString *const SHMWVContextMethodSetNavigatorBack = @"setNavigatorBack";

/// 设置导航各类功能按钮
NSString *const SHMWVContextMethodSetNavigatorButtons = @"setNavigatorButtons";

/// SHMWebView 版本
NSString *const SHMWebViewVersion = @"1.35";

@interface SHMWebView () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

/// userContentController 的名称
///
/// Default: _SMWV-UCC_
@property (nonnull, nonatomic, copy) NSString *userContentControllerName;

/// 支持的 native 方法
///
/// Default: @[@"setNavigatorTitle", @"setNavigatorBack", @"setNavigatorButtons"]
@property (nonnull, nonatomic, copy) NSArray *supportedMethods;

/// 原生点击返回的时候先执行这段 JS，根据返回值判断是否退出 WebView
@property (nullable, nonatomic, copy) NSString *goBackScript;

/// 导航条按钮点击时调用的 JS
@property (nonnull, nonatomic, strong) NSMutableDictionary *buttonScripts;

@property (nonatomic, assign) BOOL backButtonEnabled;
@property (nullable, nonatomic, strong) WKWebView *webview;

/// WebView 有没有加载完成过
@property (nonatomic, assign) BOOL everLoadFinished;

@end

@implementation SHMWebView

#pragma mark - View LifeCycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _backButtonEnabled = NO;
        _userContentControllerName = @"_SMWV-UCC_";
        _appID = @"NativeSDK-1";
        _lang = @"zh-CN";
        _dir = @"ltr";
        _supportedMethods = @[SHMWVContextMethodSetNavigatorTitle, SHMWVContextMethodSetNavigatorBack, SHMWVContextMethodSetNavigatorButtons];
        _buttonScripts = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window) {
        if (!self.webview) {
            [self createAndSetWebView];
        }
        UIView *superView = self.webview.superview;
        if (superView != self) {
            // self.webview 父 View 不存在或者不是当前 View
            if (superView) {
                [self.webview removeFromSuperview];
            }
            self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self addSubview:self.webview];
            
            // didMoveToWindow 会触发多次，防止重复加载 url，只在加载到父 View 的时候加载
            if (self.url) {
                [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
            }
        }
    }
}

- (void)removeFromSuperview {
    if (self.webview) {
        [self.webview.configuration.userContentController removeScriptMessageHandlerForName:self.userContentControllerName];
        [self.webview removeFromSuperview];
        self.webview = nil;
    }
    [super removeFromSuperview];
}

#pragma mark - Public

- (nonnull WKWebView *)createAndSetWebView {
    self.webview = [self createWebView];
    return self.webview;
}

- (void)goBackWithCallback:(void (^__nullable)(BOOL nativeGoBack))callback {
    if (!self.goBackScript) {
        // goBackScript 为空时，执行 native 的返回逻辑
        callback(true);
        return;
    }
    [self.webview evaluateJavaScript:self.goBackScript completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSNumber *handled = result;
        if ([handled boolValue]) {
            // 这里什么都不用做，js 已经处理了这个点击回调
            callback(false);
        } else {
            if ([self.webview canGoBack]) {
                // 执行 WebView 的返回逻辑
                [self.webview goBack];
                callback(false);
            } else {
                // 执行 native 的返回逻辑
                callback(true);
            }
        }
    }];
}

- (void)clickNavigatorButton:(nonnull SHMWebViewNavigatorButton *)navigatorButton {
    NSString *key = [self getButonKeyWithType:navigatorButton.type payload:navigatorButton.payload];
    NSString *script = self.buttonScripts[key];
    if (script) {
        [self.webview evaluateJavaScript:script completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            // do nothing
        }];
    }
}

+ (BOOL)isFileURL:(nonnull NSURL *)url {
    NSArray<NSString *> *pathComponents = url.pathComponents;
    
    if (pathComponents.count > 2) {
        NSArray<NSString *> * filePaths = @[
            @"docs", @"docx", // 文档类链接
            @"sheet", @"sheets", @"tables", // 表格类
            @"presentation", // PPT
            @"file", @"files", // 云文件
            @"forms", // 表单
            @"mindmaps", @"boards" // 其他套件
        ];
        
        // 可用第一段 path 作为文件类型的判断
        NSString *firstPath = pathComponents[1];
        
        return [filePaths containsObject:firstPath];
    } else {
        return NO;
    }
}


+ (BOOL)shouldOpenWindow:(NSURL *)url {
    NSArray<NSString *> *pathComponents = url.pathComponents;
    
    if (pathComponents.count > 2) {
        return [pathComponents[2] isEqualToString:@"collaborators"];
    } else {
        return NO;
    }
}

#pragma mark - Setup WebView

- (nonnull WKWebView *)createWebView {
    WKWebViewConfiguration *configuration = [self createConfig];
    WKWebView *webview = [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    
    // 禁止回弹
    webview.scrollView.bounces = NO;
    
    // 开启 JS 拉起键盘
    [self disallowKeyboardDisplayRequiresUserAction:webview];
    
    // 设置各类 delegate
    webview.UIDelegate = self;
    webview.navigationDelegate = self;
    
    return webview;
}

- (WKWebViewConfiguration *)createConfig {
    WKWebViewConfiguration *config = self.configuration ?: [[WKWebViewConfiguration alloc] init];
    
    // 设置 userAgent 后缀
    config.applicationNameForUserAgent = [NSString stringWithFormat:@"SMWV/%@ (%@; lang: %@; dir: %@)", SHMWebViewVersion, self.appID, self.lang, self.dir];

    // 添加 userContentController
    config.userContentController = [self createUserContentController];
    
    return config;
}

- (WKUserContentController *)createUserContentController {
    WKUserContentController *userContentController = [WKUserContentController new];
    
    // 添加名为 SMWV 的 userContentController
    [userContentController addScriptMessageHandler:self name:self.userContentControllerName];
    
    // 生成 userContentController 需要的接口适配脚本
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self.supportedMethods
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *methodsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:@"var context=%@;window['_SMWV-CONTEXT_']=context.reduce(function(cxt,method){cxt[method]=function(){var args = Array.prototype.slice.call(arguments);window.webkit.messageHandlers['%@'].postMessage({method:method,args:args});};return cxt;},{})", methodsString, self.userContentControllerName];
    
    // 需要在文档加载之前注入 userContentController 的接口适配代码
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [userContentController addUserScript:userScript];
    
    return userContentController;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    // 目前忽略所有来自 iFrame 的消息
    if (!message.frameInfo.isMainFrame) {
        return;
    }
    
    if ([self.userContentControllerName isEqualToString:message.name]) {
        id body = message.body;
        // 获取当前调用的 method 名称
        NSString *method = [body objectForKey:@"method"];
        
        if ([SHMWVContextMethodSetNavigatorTitle isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            // title 为需要设置的导航标题
            NSString *title = args[0];
            title = [[self class] isNotEmpty:title] ? title : self.webview.title;
            [self.delegate webview:self setNavigatorTitle:title];
        } else if ([SHMWVContextMethodSetNavigatorBack isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            // callback 为 native 导航返回按钮点击时需要执行的脚本
            NSString *goBackScript = args[0];
            goBackScript = [[self class] isNotEmpty:goBackScript] ? goBackScript : nil;
            self.goBackScript = goBackScript;
            [self setBackButtonEnabled:self.goBackScript || self.webview.canGoBack];
        } else if ([SHMWVContextMethodSetNavigatorButtons isEqualToString:method]) {
            NSArray<NSArray<NSDictionary *> *> *args = [body objectForKey:@"args"];
            NSArray<NSDictionary *> *buttons = args[0];
            NSMutableArray<SHMWebViewNavigatorButton *> *navigatorButtons = [NSMutableArray array];
            for (NSDictionary *button in buttons) {
                NSString *type = [button valueForKey:@"type"];
                if ([[self class] isNil:type]) {
                    continue;
                }
                
                NSString *payload = [button valueForKey:@"payload"];
                payload = [[self class] isNil:payload] ? nil : payload;
                NSString *callback = [button valueForKey:@"callback"];
                NSString *key = [self getButonKeyWithType:type payload:payload];
                [self.buttonScripts setObject:callback forKey:key];
                
                SHMWebViewNavigatorButton *navigatorButton = [SHMWebViewNavigatorButton new];
                navigatorButton.type = type;
                navigatorButton.payload = payload;
                [navigatorButtons addObject:navigatorButton];
            }
            [self.delegate webview:self setNavigatorButtons:navigatorButtons];
        } else {
            NSLog(@"SHMWebView: userController: unexpected method `%@` called.", method);
            // 不应走到这里的逻辑里
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler WK_SWIFT_ASYNC(3) {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:decisionHandler:)]) {
        [self.navigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction decisionHandler:decisionHandler];
    } else {
        // 只有顶层 frame 发生导航才处理，页面内部嵌套的 iframe 导航不管
        if (navigationAction.targetFrame.isMainFrame) {
            NSURL *url = navigationAction.request.URL;
            // 加载当前 WebView 初始页面放行
            if ([webView.URL isEqual:url]) {
                decisionHandler(WKNavigationActionPolicyAllow);
                return;
            }
            
            NSString *origin = url.port ?
                [NSString stringWithFormat:@"%@://%@:%@", url.scheme, url.host, url.port] :
                [NSString stringWithFormat:@"%@://%@", url.scheme, url.host];
            
            // 非石墨外部链接，拦截后做外部打开的处理
            if (origin && self.origins && ![self.origins containsObject:origin]) {
                decisionHandler(WKNavigationActionPolicyCancel);
                [self.delegate webview:self navigateToUrl:url withMethod:SHMWebViewNavigateMethodExternal];
                return;
            }
            
            // 石墨文件链接在新 SHMWebView 打开
            if ([self.class isFileURL:url]) {
                decisionHandler(WKNavigationActionPolicyCancel);
                [self.delegate webview:self navigateToUrl:url withMethod:SHMWebViewNavigateMethodNewWebView];
                return;
            }
            
            // 部分非石墨文件链接也需要在新 SHMWebView 打开
            if ([self.class shouldOpenWindow:url]) {
                decisionHandler(WKNavigationActionPolicyCancel);
                [self.delegate webview:self navigateToUrl:url withMethod:SHMWebViewNavigateMethodNewWebView];
                return;
            }
        }
        // 其他情况放行
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSURLResponse *response = navigationResponse.response;
    if (navigationResponse.forMainFrame
        && navigationResponse.canShowMIMEType
        && response.URL
        && response.MIMEType
        && ![@"text/html" isEqualToString:navigationResponse.response.MIMEType]) {
        // TODO MIME type 可以获取，且值不是 text/html，下载文件
        if ([self.delegate respondsToSelector:@selector(webview:downloadWithResponse:inNewWindow:)]) {
            // INFO 未加载完成过就表示是在新窗口打开的下载，处理下载操作后要关闭该窗口
            [self.delegate webview:self downloadWithResponse:navigationResponse.response inNewWindow:!self.everLoadFinished];
            decisionHandler(WKNavigationResponsePolicyCancel);
            return;
        }
    }
    
    if ([self.navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
        [self.navigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
    } else {
        decisionHandler(WKNavigationResponsePolicyAllow);
    }
}

//- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction preferences:(WKWebpagePreferences *)preferences decisionHandler:(void (^)(WKNavigationActionPolicy, WKWebpagePreferences *))decisionHandler WK_SWIFT_ASYNC(4) API_AVAILABLE(macos(10.15), ios(13.0)) {
//    if ([self.navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationAction:preferences:decisionHandler:)]) {
//        [self.navigationDelegate webView:webView decidePolicyForNavigationAction:navigationAction preferences:preferences decisionHandler:decisionHandler];
//    } else {
//        // TODO 不知道 decisionHandler 该默认返回什么，所以暂时禁用该方法
//    }
//}

//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler WK_SWIFT_ASYNC(3) {
//    if ([self.navigationDelegate respondsToSelector:@selector(webView:decidePolicyForNavigationResponse:decisionHandler:)]) {
//        [self.navigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:decisionHandler];
//    } else {
//        // TODO 不知道 decisionHandler 该默认返回什么，所以暂时禁用该方法
//    }
//}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    // 清除 title
    [self.delegate webview:self setNavigatorTitle:nil];
    // 清除返回脚本
    self.goBackScript = nil;
    // 更新是否显示返回按钮
    [self setBackButtonEnabled:self.webview.canGoBack];
    // 清除导航条按钮
    [self.buttonScripts removeAllObjects];
    [self.delegate webview:self setNavigatorButtons:@[]];
    
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didStartProvisionalNavigation:)]) {
        [self.navigationDelegate webView:webView didStartProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didReceiveServerRedirectForProvisionalNavigation:)]) {
        [self.navigationDelegate webView:webView didReceiveServerRedirectForProvisionalNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didFailProvisionalNavigation:withError:)]) {
        [self.navigationDelegate webView:webView didFailProvisionalNavigation:navigation withError:error];
    }
}

- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didCommitNavigation:)]) {
        [self.navigationDelegate webView:webView didCommitNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation {
    self.everLoadFinished = YES;
    [self setBackButtonEnabled:self.goBackScript || self.webview.canGoBack];
    [self.delegate webview:self setNavigatorTitle:webView.title];
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didFinishNavigation:)]) {
        [self.navigationDelegate webView:webView didFinishNavigation:navigation];
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    self.everLoadFinished = YES;
    if ([self.navigationDelegate respondsToSelector:@selector(webView:didFailNavigation:withError:)]) {
        [self.navigationDelegate webView:webView didFailNavigation:navigation withError:error];
    }
}

//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler WK_SWIFT_ASYNC_NAME(webView(_:respondTo:)) {
//    if ([self.navigationDelegate respondsToSelector:@selector(webView:didReceiveAuthenticationChallenge:completionHandler:)]) {
//        [self.navigationDelegate webView:webView didReceiveAuthenticationChallenge:challenge completionHandler:completionHandler];
//    } else {
//        // TODO 不知道 completionHandler 默认该返回什么，所以暂时禁用该方法
//    }
//}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macos(10.11), ios(9.0)) {
    if ([self.navigationDelegate respondsToSelector:@selector(webViewWebContentProcessDidTerminate:)]) {
        [self.navigationDelegate webViewWebContentProcessDidTerminate:webView];
    }
}

//- (void)webView:(WKWebView *)webView authenticationChallenge:(NSURLAuthenticationChallenge *)challenge shouldAllowDeprecatedTLS:(void (^)(BOOL))decisionHandler WK_SWIFT_ASYNC_NAME(webView(_:shouldAllowDeprecatedTLSFor:)) WK_SWIFT_ASYNC(3) API_AVAILABLE(macos(11.0), ios(14.0)) {
//    if ([self.navigationDelegate respondsToSelector:@selector(webView:authenticationChallenge:shouldAllowDeprecatedTLS:)]) {
//        [self.navigationDelegate webView:webView authenticationChallenge:challenge shouldAllowDeprecatedTLS:decisionHandler];
//    } else {
//        // TODO 不知道 decisionHandler 默认该返回什么，所以暂时禁用该方法
//    }
//}

- (void)webView:(WKWebView *)webView navigationAction:(WKNavigationAction *)navigationAction didBecomeDownload:(WKDownload *)download API_AVAILABLE(macos(11.3), ios(14.5)) {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:navigationAction:didBecomeDownload:)]) {
        [self.navigationDelegate webView:webView navigationAction:navigationAction didBecomeDownload:download];
    }
}

- (void)webView:(WKWebView *)webView navigationResponse:(WKNavigationResponse *)navigationResponse didBecomeDownload:(WKDownload *)download API_AVAILABLE(macos(11.3), ios(14.5)) {
    if ([self.navigationDelegate respondsToSelector:@selector(webView:navigationResponse:didBecomeDownload:)]) {
        [self.navigationDelegate webView:webView navigationResponse:navigationResponse didBecomeDownload:download];
    }
}

#pragma mark - WKUIDelegate

/**
 拦截 window.open
 */
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if ([self.UIDelegate respondsToSelector:@selector(webView:createWebViewWithConfiguration:forNavigationAction:windowFeatures:)]) {
        return [self.UIDelegate webView:webView createWebViewWithConfiguration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
    } else {
        NSURL *url = navigationAction.request.URL;
        NSString *host = url.host;
        // 外部链接，拦截后外部打开
        if (host && self.origins && ![self.origins containsObject:host]) {
            return [self.delegate webview:self windowOpenWithMethod:SHMWebViewNavigateMethodExternal configuration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
        } else {
            // 其他石墨内部链接在新窗口打开
            return [self.delegate webview:self windowOpenWithMethod:SHMWebViewNavigateMethodNewWebView configuration:configuration forNavigationAction:navigationAction windowFeatures:windowFeatures];
        }
    }
}

- (void)webViewDidClose:(WKWebView *)webView {
    if ([self.UIDelegate respondsToSelector:@selector(webViewDidClose:)]) {
        [self.UIDelegate webViewDidClose:webView];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    if ([self.UIDelegate respondsToSelector:@selector(webView:runJavaScriptAlertPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.UIDelegate webView:webView runJavaScriptAlertPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler();
        }];
        [alertVC addAction:okAction];
        [[self viewController] presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    if ([self.UIDelegate respondsToSelector:@selector(webView:runJavaScriptConfirmPanelWithMessage:initiatedByFrame:completionHandler:)]) {
        [self.UIDelegate webView:webView runJavaScriptConfirmPanelWithMessage:message initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(YES);
        }];
        UIAlertAction *cancalAction = [UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(NO);
        }];
        [alertVC addAction:okAction];
        [alertVC addAction:cancalAction];
        [[self viewController] presentViewController:alertVC animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    if ([self.UIDelegate respondsToSelector:@selector(webView:runJavaScriptTextInputPanelWithPrompt:defaultText:initiatedByFrame:completionHandler:)]) {
        [self.UIDelegate webView:webView runJavaScriptTextInputPanelWithPrompt:prompt defaultText:defaultText initiatedByFrame:frame completionHandler:completionHandler];
    } else {
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:(UIAlertControllerStyleAlert)];
        [alertVC addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"input";
        }];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            UITextField *tf = [alertVC.textFields firstObject];
            completionHandler(tf.text);
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
            completionHandler(defaultText);
        }];
        [alertVC addAction:okAction];
        [alertVC addAction:cancelAction];
        [[self viewController] presentViewController:alertVC animated:YES completion:nil];
    }
}

//- (void)webView:(WKWebView *)webView requestMediaCapturePermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame type:(WKMediaCaptureType)type decisionHandler:(void (^)(WKPermissionDecision decision))decisionHandler {
//}

//- (void)webView:(WKWebView *)webView requestDeviceOrientationAndMotionPermissionForOrigin:(WKSecurityOrigin *)origin initiatedByFrame:(WKFrameInfo *)frame decisionHandler:(void (^)(WKPermissionDecision decision))decisionHandler API_AVAILABLE(ios(15.0)) API_UNAVAILABLE(macos);

//- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo API_DEPRECATED_WITH_REPLACEMENT("webView:contextMenuConfigurationForElement:completionHandler:", ios(10.0, 13.0));

//- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_DEPRECATED_WITH_REPLACEMENT("webView:contextMenuConfigurationForElement:completionHandler:", ios(10.0, 13.0));

//- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_DEPRECATED_WITH_REPLACEMENT("webView:contextMenuForElement:willCommitWithAnimator:", ios(10.0, 13.0));

//- (void)webView:(WKWebView *)webView contextMenuConfigurationForElement:(WKContextMenuElementInfo *)elementInfo completionHandler:(void (^)(UIContextMenuConfiguration * _Nullable configuration))completionHandler WK_SWIFT_ASYNC_NAME(webView(_:contextMenuConfigurationFor:)) API_AVAILABLE(ios(13.0));

- (void)webView:(WKWebView *)webView contextMenuWillPresentForElement:(WKContextMenuElementInfo *)elementInfo API_AVAILABLE(ios(13.0)) {
    if ([self.UIDelegate respondsToSelector:@selector(webView:contextMenuWillPresentForElement:)]) {
        [self.UIDelegate webView:webView contextMenuWillPresentForElement:elementInfo];
    }
}

- (void)webView:(WKWebView *)webView contextMenuForElement:(WKContextMenuElementInfo *)elementInfo willCommitWithAnimator:(id <UIContextMenuInteractionCommitAnimating>)animator API_AVAILABLE(ios(13.0)) {
    if ([self.UIDelegate respondsToSelector:@selector(webView:contextMenuForElement:willCommitWithAnimator:)]) {
        [self.UIDelegate webView:webView contextMenuForElement:elementInfo willCommitWithAnimator:animator];
    }
}

- (void)webView:(WKWebView *)webView contextMenuDidEndForElement:(WKContextMenuElementInfo *)elementInfo API_AVAILABLE(ios(13.0)) {
    if ([self.UIDelegate respondsToSelector:@selector(webView:contextMenuDidEndForElement:)]) {
        [self.UIDelegate webView:webView contextMenuDidEndForElement:elementInfo];
    }
}

//- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macos(10.12));

#pragma mark - Setter

- (void)setUrl:(NSURL *)url {
    _url = url;
    if (_url && _webview && _webview.superview) {
        [_webview loadRequest:[NSURLRequest requestWithURL:_url]];
    }
}

- (void)setBackButtonEnabled:(BOOL)backButtonEnabled {
    if (_backButtonEnabled == backButtonEnabled) {
        return;
    }
    _backButtonEnabled = backButtonEnabled;
    if ([self.delegate respondsToSelector:@selector(webview:setBackButtonEnabled:)]) {
        [self.delegate webview:self setBackButtonEnabled:_backButtonEnabled];
    }
}

#pragma mark - Getter

- (UIViewController *)viewController {
    UIResponder *responder = self;
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return (UIViewController *)responder;
}

#pragma mark - Private

#if !TARGET_OS_OSX
-(void)disallowKeyboardDisplayRequiresUserAction:(WKWebView *)webview {
    UIView* subview;

    for (UIView* view in webview.scrollView.subviews) {
        if([[view.class description] hasPrefix:@"WK"])
            subview = view;
    }

    if(subview == nil) return;

    Class class = subview.class;

    NSOperatingSystemVersion iOS_11_3_0 = (NSOperatingSystemVersion){11, 3, 0};
    NSOperatingSystemVersion iOS_12_2_0 = (NSOperatingSystemVersion){12, 2, 0};
    NSOperatingSystemVersion iOS_13_0_0 = (NSOperatingSystemVersion){13, 0, 0};

    Method method;
    IMP override;

    if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_13_0_0]) {
        // iOS 13.0.0 - Future
        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:activityStateChanges:userObject:");
        method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
    }
    else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_12_2_0]) {
        // iOS 12.2.0 - iOS 13.0.0
        SEL selector = sel_getUid("_elementDidFocus:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
        method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
    }
    else if ([[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion: iOS_11_3_0]) {
        // iOS 11.3.0 - 12.2.0
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:changingActivityState:userObject:");
        method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, BOOL arg3, id arg4) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3, arg4);
        });
    } else {
        // iOS 9.0 - 11.3.0
        SEL selector = sel_getUid("_startAssistingNode:userIsInteracting:blurPreviousNode:userObject:");
        method = class_getInstanceMethod(class, selector);
        IMP original = method_getImplementation(method);
        override = imp_implementationWithBlock(^void(id me, void* arg0, BOOL arg1, BOOL arg2, id arg3) {
            ((void (*)(id, SEL, void*, BOOL, BOOL, id))original)(me, selector, arg0, TRUE, arg2, arg3);
        });
    }

    method_setImplementation(method, override);
}
#endif // !TARGET_OS_OSX

- (NSString *)getButonKeyWithType:(nonnull NSString *)type payload:(nullable NSString *)payload {
    return [NSString stringWithFormat:@"type:%@_payload:%@", type, payload ?: @"nil"];
}

+ (BOOL)isEmpty:(nullable NSString *)string {
    return [self isNil:string] || [string isEqualToString:@""];
}

+ (BOOL)isNotEmpty:(nullable NSString *)string {
    return ![self isEmpty:string];
}

+ (BOOL)isNil:(nullable id)object {
    return ![self isNotNil:object];
}

+ (BOOL)isNotNil:(nullable id)object {
    return object && ![object isKindOfClass:[NSNull class]];
}

@end
