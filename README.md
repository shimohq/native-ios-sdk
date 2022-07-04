# native-ios-sdk

iOS 接石墨 mobile web 的 native SDK

## 运行 Demo

```bash
cd <native-ios-sdk>
pod install
open NativeSDK.xcworkspace
```

## 接入 SHMWebView

SHMWebView 为对接石墨 mobile web 的封装，使用说明参考头文件 [SHMWebView.h](https://github.com/shimohq/native-ios-sdk/blob/main/NativeSDK/SHMWebView/SHMWebView.h)，
具体封装方法参考 [SHMWebViewController.m](https://github.com/shimohq/native-ios-sdk/blob/main/NativeSDK/SHMWebViewController.m)

Example:

```
- (SHMWebView *)createWebView {
    SHMWebView *webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
    // [必选项] 配置 当前 App 的 ID
    webview.appID = <your app id>;
    // [必选项] 配置打开的 URL
    webview.url = @"https://shimo.im/recent";
    // [可选项] 配置 WebView 内打开的链接域名白名单
    webview.hosts = @[@"shimo.im", @"uploader.shimo.im"];
    // [必选项] 配置 SHMWebViewDelegate
    webview.delegate = self;
    return webview;
}

#pragma mark - SHMWebViewDelegate

// TODO 实现 SHMWebViewDelegate 代理
```

### 上传

WKWebView 默认支持上传，不需要做额外配置

### 下载

#### 配置 hosts

SHMWebView 信任 hosts 需要添加下载 host: `uploader.<your shimo host>`，如果未配置附件链接将以外部浏览器的方式打开，配置后将在 App 内打开。

Example：

```
SHMWebView *webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
webview.hosts = @[@"shimo.im", @"uploader.shimo.im"];
```

### 监听文件下载

实现 `SHMWebViewDelegate` 的

```
/// 监听文件下载
///
/// 当 url 请求返回的 MIME type 不是 text/html 时，该请求当下载处理。如果不实现该方法，将直接在 WebView 打开。
/// @param webview SHMWebView 实例
/// @param response url fileName MIMEType 等信息
/// @param inNewWindow 是否是在新窗口打开的下载，如果是的打开下载界面时要关闭当前窗口
- (void)webview:(nonnull SHMWebView *)webview downloadWithResponse:(nonnull NSURLResponse *)response inNewWindow:(BOOL)inNewWindow;
```

监听 SHMWebView 内的文件下载事件。

Example：

```
- (void)viewDidLoad {
    [super viewDidLoad];

    SHMWebView *webview = [[SHMWebView alloc] initWithFrame:self.view.bounds];
    webview.delegate = self;
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
```
