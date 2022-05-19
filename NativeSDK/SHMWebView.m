//
//  SHMWebView.m
//  WebView
//
//  Created by 陈阳 on 2022/5/18.
//

#import <Foundation/Foundation.h>
#import "SHMWebView.h"
#import "objc/runtime.h"

// 设置导航文字标题
NSString *const SMWVContextMethodSetNavigatorTitle = @"setNavigatorTitle";

// 设置导航返回按钮
NSString *const SMWVContextMethodSetNavigatorBack = @"setNavigatorBack";

// 设置导航各类功能按钮
NSString *const SMWVContextMethodSetNavigatorButtons = @"setNavigatorButtons";

// userContentController 的名称，这里可以自定义
NSString *const SMWVUserContentControllerName = @"_SMWV-UCC_";

// 当前石墨部署环境域名
NSString *const SMWVDeployHost = @"shimo.im";


@interface SHMWebView () <WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler>

@end

@implementation SHMWebView

+ (NSArray *)supportedMethods {
    static NSArray *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 定义支持的 native 方法
        // TODO: 需要自行筛选实现的接口
        instance = @[SMWVContextMethodSetNavigatorTitle, SMWVContextMethodSetNavigatorBack, SMWVContextMethodSetNavigatorButtons];
    });

    return instance;
}

- (instancetype)initWithFrame:(CGRect)frame {
    WKWebViewConfiguration *config = [self createConfig];
    self = [super initWithFrame:frame configuration:config];
    [self setup];
    return self;
}

- (void)setup {
    // 禁止回弹
    self.scrollView.bounces = NO;
    
    // 开启 JS 拉起键盘
    [self disallowKeyboardDisplayRequiresUserAction];
    
    // 设置各类 delegate
    self.UIDelegate = self;
    self.navigationDelegate = self;
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
    [userContentController addScriptMessageHandler:self name:SMWVUserContentControllerName];
    
    // 生成 userContentController 需要的接口适配脚本
    NSArray *methodsArray = [self.class supportedMethods];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:methodsArray
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:nil];
    NSString *methodsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSString *script = [NSString stringWithFormat:@"var context=%@;window['_SMWV-CONTEXT_']=context.reduce(function(cxt,method){cxt[method]=function(){var args = Array.prototype.slice.call(arguments);window.webkit.messageHandlers['%@'].postMessage({method:method,args:args});};return cxt;},{})", methodsString, SMWVUserContentControllerName];
    
    // 需要在文档加载之前注入 userContentController 的接口适配代码
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [userContentController addUserScript:userScript];
    
    return userContentController;
}

// 需要在当前 WebView 销毁时调用，防止内存泄露
- (void)removeUserContentController {
    WKUserContentController *userContentController = self.configuration.userContentController;
    [userContentController removeScriptMessageHandlerForName:SMWVUserContentControllerName];
}

- (BOOL)isFileURL:(NSURL *)url {
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

#if !TARGET_OS_OSX
-(void)disallowKeyboardDisplayRequiresUserAction
{

    UIView* subview;

    for (UIView* view in self.scrollView.subviews) {
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


#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([SMWVUserContentControllerName isEqualToString:message.name]) {
        id body = message.body;
        // 获取当前调用的 method 名称
        NSString *method = [body objectForKey:@"method"];
        
        
        if ([SMWVContextMethodSetNavigatorTitle isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            NSString *title = args[0];
            // title 为需要设置的导航标题
            NSLog(@"userController: `%@` called with title: %@", method, title);
            // TODO: 实现对应的逻辑
        } else if ([SMWVContextMethodSetNavigatorBack isEqualToString:method]) {
            NSArray<NSString *> *args = [body objectForKey:@"args"];
            NSString *callback = args[0];
            // callback 为 native 导航返回按钮点击时需要执行的脚本
            NSLog(@"userController: `%@` called with callback: %@", method, callback);
            
            // TODO: 需要用户点击导航栏返回按钮时调用下面这个回调
            void (^cb)(void) = ^() {
                [self evaluateJavaScript:callback completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                    if (result) {
                        NSLog(@"userController: %@ callback returned 'true'", method);
                        // 这里什么都不用做，js 已经处理了这个点击回调
                    } else {
                        NSLog(@"userController: %@ callback returned 'false'", method);
                        // 如果这里 result 为 false，需要执行 native 端的返回逻辑
                        // TODO: 执行 native 的返回逻辑
                    }
                }];
            };

            // TODO: 删除这行，这里只是模拟用户点击返回按钮
            cb();
        } else if ([SMWVContextMethodSetNavigatorButtons isEqualToString:method]) {
            NSArray<NSDictionary *> *buttons = [body objectForKey:@"args"];
            
            
            for (NSDictionary *button in buttons) {
                NSString *type = [button valueForKey:@"type"];
                NSLog(@"userController: `%@` called with button\n type: %@", method, type);
                
                NSString *payload = [button valueForKey:@"payload"];
                NSLog(@"userController: `%@` called with button\n payload: %@", method, payload);
                
                // TODO: 根据 type 和约定的 payload 渲染导航按钮
                
                NSString *callback = [button valueForKey:@"callback"];
                NSLog(@"userController: `%@` called with button\n callback: %@", method, callback);
           
                // TODO: 在导航按钮点击时调用这个 lambda 回调
                void (^cb)(void) = ^() {
                    [self evaluateJavaScript:callback completionHandler:^(id _Nullable result, NSError * _Nullable error) {
                        
                    }];
                };
            }
            
    
            // TODO: 实现对应的逻辑
        } else {
            NSLog(@"userController: unexpected method `%@` called.", method);
            // 不应走到这里的逻辑里
        }
    }
}


# pragma mark - WKNavigationDelegate
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {

    // 只有顶层 frame 发生导航才处理，页面内部嵌套的 iframe 导航不管
    if (navigationAction.targetFrame.isMainFrame) {
        NSLog(@"navigate: %@", navigationAction.request.URL);
        
        // 加载当前 WebView 初始页面放行
        if ([webView.URL isEqual:navigationAction.request.URL]) {
            decisionHandler(WKNavigationActionPolicyAllow);
            return;
        }
        
        NSString *host = navigationAction.request.URL.host;
        // 非石墨外部链接，拦截后做外部打开的处理
        if (![SMWVDeployHost isEqualToString:host]) {
            // TODO: 在应用外部或其他 VC 中打开这个请求
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        if ([self isFileURL:navigationAction.request.URL]) {
            // TODO: 二级页面，需要新开 VC 打开这个请求
            decisionHandler(WKNavigationActionPolicyCancel);
            NSLog(@"navigate to file: %@", navigationAction.request.URL);
            return;
        }
    }
    
    // 其他情况放行
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

// TODO: 需自行实现当前应用中的 alert WKUIDelegate
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alertVC addAction:okAction];
    [[self viewController] presentViewController:alertVC animated:YES completion:nil];
}

// TODO: 需自行实现当前应用中的 confirm WKUIDelegate
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

// TODO: 需自行实现当前应用中的 prompt WKUIDelegate
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

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSLog(@"open window: %@", navigationAction.request.URL);
    
    NSString *host = navigationAction.request.URL.host;
    // 非石墨外部链接，拦截后做外部打开的处理
    if (![SMWVDeployHost isEqualToString:host]) {
        // TODO: 在应用外部或其他 VC 中打开这个请求
        return [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    }
    
    if ([self isFileURL:navigationAction.request.URL]) {
        // TODO: 二级页面，需要新开 VC 打开这个请求
        return [[WKWebView alloc] initWithFrame:self.bounds configuration:configuration];
    }
    
    // 其他请求直接在当前页面打开
    return nil;
}

@end
