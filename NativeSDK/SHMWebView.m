//
//  SHMWebView.m
//  WebView
//
//  Created by 陈阳 on 2022/5/18.
//

#import "SHMWebView.h"

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// 设置导航文字标题
NSString *const SHMWVContextMethodSetNavigatorTitle = @"setNavigatorTitle";

// 设置导航返回按钮
NSString *const SHMWVContextMethodSetNavigatorBack = @"setNavigatorBack";

// 设置导航各类功能按钮
NSString *const SHMWVContextMethodSetNavigatorButtons = @"setNavigatorButtons";

@interface SHMWebView () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

/// 原生点击返回的时候先执行这段 JS，根据返回值判断是否退出 WebView
@property (nonatomic, strong) NSString *goBackScript;
/// 导航条按钮点击时调用的 JS
@property (nonatomic, strong) NSMutableDictionary *buttonScripts;

@property (nonatomic, strong) WKWebView *webview;

@end

@implementation SHMWebView

#pragma mark - View LifeCycle

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _supportedMethods = @[SHMWVContextMethodSetNavigatorTitle, SHMWVContextMethodSetNavigatorBack, SHMWVContextMethodSetNavigatorButtons];
        _buttonScripts = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)didMoveToWindow {
    if (self.window && !self.webview) {
        self.webview = [self createWebView];
        // 禁止回弹
        self.webview.scrollView.bounces = NO;
        
        // 开启 JS 拉起键盘
        [self disallowKeyboardDisplayRequiresUserAction];
        
        // 设置各类 delegate
        self.webview.UIDelegate = self;
        self.webview.navigationDelegate = self;
        
        self.webview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.webview];
        [self loadUrl];
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

- (void)goBackWithCallback:(void (^__nullable)(BOOL nativeGoBack))callback {
    if (!self.goBackScript) {
        // goBackScript 为空时，执行 native 的返回逻辑
        callback(true);
        return;
    }
    [self.webview evaluateJavaScript:self.goBackScript completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        if (result) {
            NSLog(@"SHMWebView: goBack return 'true' goBackScript: %@", self.goBackScript);
            // 这里什么都不用做，js 已经处理了这个点击回调
            callback(false);
        } else {
            NSLog(@"SHMWebView: goBack return 'false' goBackScript: %@", self.goBackScript);
            // 如果这里 result 为 false，需要执行 native 端的返回逻辑
            // 执行 native 的返回逻辑
            callback(true);
        }
    }];
}

- (void)clickButtonWithType:(nonnull NSString *)type payload:(nonnull NSString *)payload {
    NSString *key = [self getButonKeyWithType:type payload:payload];
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

#pragma mark - Setup WebView

- (WKWebView *)createWebView {
    WKWebViewConfiguration *config = [self createConfig];
    return [[WKWebView alloc] initWithFrame:self.bounds configuration:config];
}

- (WKWebViewConfiguration *)createConfig {
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
    
    // 设置 userAgent
    // 根据实际情况填充 lang 和 dir 字段
    config.applicationNameForUserAgent = [NSString stringWithFormat:@"SMWV/1.35 (HWMT-730; lang: %@; dir: %@)", @"zh-CN", @"ltr"];

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
    if ([self.userContentControllerName isEqualToString:message.name]) {
        id body = message.body;
        // 获取当前调用的 method 名称
        NSString *method = [body objectForKey:@"method"];
        
        if ([SHMWVContextMethodSetNavigatorTitle isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            NSString *title = args[0];
            // title 为需要设置的导航标题
            NSLog(@"SHMWebView: userController: `%@` called with title: %@", method, title);
            [self.shmWebViewDelegate webview:self setNavigatorTitle:title];
        } else if ([SHMWVContextMethodSetNavigatorBack isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            self.goBackScript = args[0];
            // callback 为 native 导航返回按钮点击时需要执行的脚本
            NSLog(@"SHMWebView: userController: `%@` called with goBackScript: %@", method, self.goBackScript);
        } else if ([SHMWVContextMethodSetNavigatorButtons isEqualToString:method]) {
            NSArray<NSArray<NSDictionary *> *> *args = [body objectForKey:@"args"];
            NSArray<NSDictionary *> *buttons = args[0];
            
            for (NSDictionary *button in buttons) {
                NSString *type = [button valueForKey:@"type"];
                NSLog(@"SHMWebView: userController: `%@` called with button\n type: %@", method, type);
                
                NSString *payload = [button valueForKey:@"payload"];
                NSLog(@"SHMWebView: userController: `%@` called with button\n payload: %@", method, payload);
                
                NSString *callback = [button valueForKey:@"callback"];
                NSLog(@"SHMWebView: userController: `%@` called with button\n callback: %@", method, callback);
                
                NSString *key = [self getButonKeyWithType:type payload:payload];
                [self.buttonScripts setObject:callback forKey:key];
                [self.shmWebViewDelegate webview:self setNavigatorButtonWithType:type payload:payload];
            }
        } else {
            NSLog(@"SHMWebView: userController: unexpected method `%@` called.", method);
            // 不应走到这里的逻辑里
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    // 只有顶层 frame 发生导航才处理，页面内部嵌套的 iframe 导航不管
    if (navigationAction.targetFrame.isMainFrame) {
        NSLog(@"SHMWebView: navigate: %@", navigationAction.request.URL);
        
        // 加载当前 WebView 初始页面放行
        if ([webView.URL isEqual:navigationAction.request.URL]) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
        
        NSString *host = navigationAction.request.URL.host;
        // 非石墨外部链接，拦截后做外部打开的处理
        if (![self.host isEqualToString:host]) {
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        if ([self.class isFileURL:navigationAction.request.URL]) {
            decisionHandler(WKNavigationActionPolicyCancel);
            NSLog(@"SHMWebView: navigate to file: %@", navigationAction.request.URL);
            return;
        }
    }
    
    // 其他情况放行
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alertVC addAction:okAction];
    [[self viewController] presentViewController:alertVC animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
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

- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
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

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSLog(@"SHMWebView: open window: %@", navigationAction.request.URL);
    NSString *host = navigationAction.request.URL.host;
    // 非石墨外部链接，拦截后做外部打开的处理
    if (![self.host isEqualToString:host]) {
        return [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    }
    
    if ([self.class isFileURL:navigationAction.request.URL]) {
        return [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    }
    
    // 其他请求直接在当前页面打开
    return nil;
}

#pragma mark - Getter

- (NSString *)userContentControllerName {
    if (!_userContentControllerName) {
        _userContentControllerName = @"_SMWV-UCC_";
    }
    return _userContentControllerName;
}

#pragma mark - Setter

- (void)setUrl:(NSURL *)url {
    _url = url;
    [self loadUrl];
}

#pragma mark - Private

- (void)loadUrl {
    if (self.webview && self.url) {
        [self.webview loadRequest:[NSURLRequest requestWithURL:self.url]];
    }
}

#if !TARGET_OS_OSX
-(void)disallowKeyboardDisplayRequiresUserAction
{
    UIView* subview;

    for (UIView* view in self.webview.scrollView.subviews) {
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

- (NSString *)getButonKeyWithType:(nonnull NSString *)type payload:(nonnull NSString *)payload {
    return [NSString stringWithFormat:@"type:%@_payload:%@", type, payload];
}

@end
