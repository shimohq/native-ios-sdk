//
//  SHMWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMWebViewController.h"

#import <Masonry/Masonry.h>

@interface SHMWebViewController () <SHMWebViewDelegate, WKUIDelegate, WKNavigationDelegate>

@property (nullable, nonatomic, strong) NSURL *url;
@property (nullable, nonatomic, copy) NSString *host;
@property (nullable, nonatomic, copy) NSString *applicationNameForUserAgent;

@property (nullable, nonatomic, strong) SHMWebView *webview;

@property (nonatomic, strong) UIBarButtonItem *backNavigatorButton;
@property (nonatomic, strong) UIBarButtonItem *closeNavigatorButton;

@property (nonatomic, strong) SHMWebViewNavigatorButton *shareNavigatorButton;
@property (nonatomic, strong) SHMWebViewNavigatorButton *menuNavigatorButton;

@end

@implementation SHMWebViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _applicationNameForUserAgent = @"SMWV/1.35  (HWMT-730; lang: zh-CN; dir: ltr)";
    }
    return self;
}

- (instancetype)initWithWebView:(SHMWebView *)webview {
    self = [self init];
    if (self) {
        _webview = webview;
    }
    return self;
}

- (instancetype)initWithUrl:(NSURL *)url host:(NSString *)host {
    self = [self init];
    if (self) {
        _url = url;
        _host = host;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    self.backNavigatorButton = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(onGoBack)];
    self.closeNavigatorButton = [[UIBarButtonItem alloc] initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(onClose)];
    self.navigationItem.leftBarButtonItems = @[self.closeNavigatorButton];
    
    if (!self.webview) {
        self.webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
        self.webview.host = self.host;
        self.webview.url = self.url;
        self.webview.applicationNameForUserAgent = self.applicationNameForUserAgent;
    }
    
    self.webview.delegate = self;
    // TODO SHMWebView 已实现的 UIDelegate 不满足要求的时候才设置
    self.webview.UIDelegate = self;
    // TODO SHMWebView 已实现的 navigationDelegate 不满足要求的时候才设置
    self.webview.navigationDelegate = self;
    
    [self.view addSubview:self.webview];
    [self.webview mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
}

#pragma mark - Action

- (void)onGoBack {
    [self.webview goBackWithCallback:^(BOOL nativeGoBack) {
        if (nativeGoBack) {
            if ([self.webview.webview canGoBack]) {
                [self.webview.webview goBack];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
            }
        }
    }];
}

- (void)onClose {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onShare {
    [self.webview clickNavigatorButton:self.shareNavigatorButton];
}

- (void)onMenu {
    [self.webview clickNavigatorButton:self.menuNavigatorButton];
}

#pragma mark - SHMWebViewDelegate

- (void)webview:(nonnull SHMWebView *)webview setNavigatorTitle:(nullable NSString *)title {
    self.title = title ?: @"石墨文档";
}

- (void)webview:(nonnull SHMWebView *)webview setNavigatorButtons:(nonnull NSArray<SHMWebViewNavigatorButton *> *)buttons {
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    [buttons enumerateObjectsUsingBlock:^(SHMWebViewNavigatorButton * _Nonnull button, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([@"share" isEqualToString:button.type]) {
            self.shareNavigatorButton = button;
            UIBarButtonItem *shareBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Share" style:UIBarButtonItemStylePlain target:self action:@selector(onShare)];
            [rightBarButtonItems addObject:shareBarButtonItem];
        } else if ([@"menu" isEqualToString:button.type]) {
            self.menuNavigatorButton = button;
            UIBarButtonItem *menuBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Menu" style:UIBarButtonItemStylePlain target:self action:@selector(onMenu)];
            [rightBarButtonItems addObject:menuBarButtonItem];
        }
    }];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
}

- (void)webview:(nonnull SHMWebView *)webview setBackButtonEnable:(BOOL)backButtonVisible {
    self.navigationItem.leftBarButtonItems = backButtonVisible ? @[self.backNavigatorButton, self.closeNavigatorButton] : @[self.closeNavigatorButton];
}

#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }];
    [alertVC addAction:okAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:message message:@"" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }];
    UIAlertAction *cancalAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancalAction];
    [self presentViewController:alertVC animated:YES completion:nil];
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
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:(UIAlertActionStyleCancel) handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(defaultText);
    }];
    [alertVC addAction:okAction];
    [alertVC addAction:cancelAction];
    [self presentViewController:alertVC animated:YES completion:nil];
}

- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    NSString *host = navigationAction.request.URL.host;
    // 非石墨外部链接，拦截后做外部打开的处理
    if (![self.host isEqualToString:host]) {
        // TODO: 在应用外部或其他 VC 中打开这个请求
        
        SHMWebView *shmWebview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
        shmWebview.host = self.host;
        shmWebview.applicationNameForUserAgent = self.applicationNameForUserAgent;
        shmWebview.url = navigationAction.request.URL;
        shmWebview.configuration = configuration;
        WKWebView *wkWebView = [shmWebview createAndSetWebView];
        
        SHMWebViewController *viewController = [[SHMWebViewController alloc] initWithWebView:shmWebview];
        [self.navigationController pushViewController:viewController animated:YES];
        return wkWebView;
    }
    
    if ([SHMWebView isFileURL:navigationAction.request.URL]) {
        // TODO: 二级页面，需要新开 VC 打开这个请求
        
        SHMWebView *shmWebview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
        shmWebview.host = self.host;
        shmWebview.applicationNameForUserAgent = self.applicationNameForUserAgent;
        shmWebview.url = navigationAction.request.URL;
        shmWebview.configuration = configuration;
        WKWebView *wkWebView = [shmWebview createAndSetWebView];
        
        SHMWebViewController *viewController = [[SHMWebViewController alloc] initWithWebView:shmWebview];
        [self.navigationController pushViewController:viewController animated:YES];
        return wkWebView;
    }
    
    // 其他请求直接在当前页面打开
    return nil;
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
            
            // TODO: 在应用外部或其他 VC 中打开这个请求
            SHMWebViewController *viewController = [[SHMWebViewController alloc] initWithUrl:navigationAction.request.URL
                                                                                        host:self.host];
            [self.navigationController pushViewController:viewController animated:YES];
            return;
        }
        
        if ([SHMWebView isFileURL:navigationAction.request.URL]) {
            NSLog(@"SHMWebView: navigate to file: %@", navigationAction.request.URL);
            decisionHandler(WKNavigationActionPolicyCancel);
            
            // TODO: 二级页面，需要新开 VC 打开这个请求
            SHMWebViewController *viewController = [[SHMWebViewController alloc] initWithUrl:navigationAction.request.URL
                                                                                        host:self.host];
            [self.navigationController pushViewController:viewController animated:YES];
            return;
        }
    }
    
    // 其他情况放行
    decisionHandler(WKNavigationActionPolicyAllow);
}

@end
