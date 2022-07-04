//
//  SHMWebViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMWebViewController.h"
#import "SHMOtherWebViewController.h"
#import "SHMDownloadViewController.h"

#import <Masonry/Masonry.h>

typedef NS_ENUM(NSUInteger, SHMWebViewOpenUrlMethod) {
    // 新窗口使用非 SHMWebView 打开
    SHMWebViewOpenUrlMethodNotSHMWebView,
    // 新窗口使用 SHMWebView 打开
    SHMWebViewOpenUrlMethodSHMWebView,
    // 外部浏览器打开
    SHMWebViewOpenUrlMethodExternal
};

@interface SHMWebViewController () <SHMWebViewDelegate>

@property (nullable, nonatomic, copy) NSString *appID;

@property (nonatomic, strong) UIBarButtonItem *backNavigatorButton;
@property (nonatomic, strong) UIBarButtonItem *closeNavigatorButton;

@property (nonatomic, strong) SHMWebViewNavigatorButton *shareNavigatorButton;
@property (nonatomic, strong) SHMWebViewNavigatorButton *menuNavigatorButton;

/**
 打开外部链接的方法
 */
@property (nonatomic, assign) SHMWebViewOpenUrlMethod openUrlMethod;

@end

@implementation SHMWebViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _appID = @"HWMT-730";
        // TODO 打开外部链接的方法
        _openUrlMethod = SHMWebViewOpenUrlMethodExternal;
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
    
    if (self.webview) {
        if (self.webview.superview) {
            [self.webview removeFromSuperview];
        }
    }
    self.webview = [self createWebView];
    // [必选项] 配置打开的 URL
    self.webview.url = self.url;
    // [必选项] 配置 SHMWebViewDelegate
    self.webview.delegate = self;
    
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
            [self.navigationController popViewControllerAnimated:YES];
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

- (void)webview:(nonnull SHMWebView *)webview navigateToUrl:(nullable NSURL *)url withMethod:(SHMWebViewNavigateMethod)method {
    if (method == SHMWebViewNavigateMethodExternal) {
        // TODO: 在应用外部或其他 VC 中打开这个请求
        switch (self.openUrlMethod) {
            case SHMWebViewOpenUrlMethodExternal:
                // TODO 用外部浏览器打开
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                break;
            case SHMWebViewOpenUrlMethodSHMWebView: {
                // TODO 用 SHMWebView 打开外部链接
                SHMWebViewController *viewController = [[SHMWebViewController alloc] init];
                viewController.url = url;
                [self.navigationController pushViewController:viewController animated:YES];
                break;
            }
            default: {
                // TODO 用非 SHMWebView 打开外部链接
                SHMOtherWebViewController *viewController = [[SHMOtherWebViewController alloc] init];
                viewController.url = url;
                [self.navigationController pushViewController:viewController animated:YES];
                break;
            }
        }
    } else {
        // TODO: 二级页面，需要新开 VC 打开这个请求
        SHMWebViewController *viewController = [[SHMWebViewController alloc] init];
        viewController.url = url;
        viewController.hosts = self.hosts;
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (nullable WKWebView *)webview:(nonnull SHMWebView *)webview
           windowOpenWithMethod:(SHMWebViewNavigateMethod)method
                  configuration:(nonnull WKWebViewConfiguration *)configuration
            forNavigationAction:(nonnull WKNavigationAction *)navigationAction
                 windowFeatures:(nonnull WKWindowFeatures *)windowFeatures {
    NSURL *url = navigationAction.request.URL;
    if (method == SHMWebViewNavigateMethodExternal) {
        // TODO: 在应用外部或其他 VC 中打开这个请求
        switch (self.openUrlMethod) {
            case SHMWebViewOpenUrlMethodExternal:
                // TODO 用外部浏览器打开
                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
                return [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
                break;
            case SHMWebViewOpenUrlMethodSHMWebView: {
                // TODO 用 SHMWebView 中打开外部链接
                SHMWebView *shmWebview = [self createWebView];
                shmWebview.configuration = configuration;
                WKWebView *wkWebView = [shmWebview createAndSetWebView];
                
                SHMWebViewController *viewController = [[SHMWebViewController alloc] init];
                viewController.url = url;
                viewController.webview = shmWebview;
                [self.navigationController pushViewController:viewController animated:YES];
                return wkWebView;
                break;
            }
            default: {
                // TODO 用非 SHMWebView 中打开外部链接
                WKWebView *wkWebView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:configuration];
                SHMOtherWebViewController *viewController = [[SHMOtherWebViewController alloc] init];
                viewController.webview = wkWebView;
                viewController.url = url;
                [self.navigationController pushViewController:viewController animated:YES];
                return wkWebView;
                break;
            }
        }
    } else {
        // TODO: 内部链接新开 VC 打开这个请求
        SHMWebView *shmWebview = [self createWebView];
        shmWebview.configuration = configuration;
        WKWebView *wkWebView = [shmWebview createAndSetWebView];
        
        SHMWebViewController *viewController = [[SHMWebViewController alloc] init];
        viewController.hosts = self.hosts;
        viewController.url = url;
        viewController.webview = shmWebview;
        [self.navigationController pushViewController:viewController animated:YES];
        
        return wkWebView;
    }
}

- (void)webview:(nonnull SHMWebView *)webview setNavigatorTitle:(nullable NSString *)title {
    self.title = (title && ![title isEqualToString:@""]) ? title : @"石墨文档";
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

- (void)webview:(nonnull SHMWebView *)webview setBackButtonEnabled:(BOOL)backButtonVisible {
    self.navigationItem.leftBarButtonItems = backButtonVisible ? @[self.backNavigatorButton, self.closeNavigatorButton] : @[self.closeNavigatorButton];
}

- (void)webview:(nonnull SHMWebView *)webview downloadWithResponse:(nonnull NSURLResponse *)response inNewWindow:(BOOL)inNewWindow {
    SHMDownloadViewController *viewController = [[SHMDownloadViewController alloc] init];
    viewController.response = response;
    if (inNewWindow) {
        NSMutableArray *viewControllers = [self.navigationController.viewControllers mutableCopy];
        UIViewController *currentViewController = webview.viewController;
        if (currentViewController) {
            [viewControllers removeObject:currentViewController];
        }
        [viewControllers addObject:viewController];
        [self.navigationController setViewControllers:viewControllers animated:NO];
    } else {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - Private

- (SHMWebView *)createWebView {
    SHMWebView *webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
    // 配置 WebView 内打开的链接域名白名单
    webview.hosts = self.hosts;
    // 配置 当前 App 的 ID
    webview.appID = self.appID;
    return webview;
}

@end
