//
//  SHMViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMViewController.h"

#import <Masonry/Masonry.h>

#import "SHMWebViewController.h"


NSString *const SHMDataTitleKey = @"title";
NSString *const SHMDataUrlKey = @"url";
NSString *const SHMDataHostKey = @"host";

@interface SHMViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) NSArray<NSDictionary *> *datas;

@end

@implementation SHMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"石墨 iOS SDK";
    // https://uploader.shimo.im/ 为附件下载地址，如果未配置附件链接将以外部浏览器的方式打开，配置后将在 App 内打开
    NSArray *origins = @[@"https://shimo.im", @"https://uploader.shimo.im"];
    
    self.datas = @[
        @{
            SHMDataTitleKey: @"Demo",
            SHMDataUrlKey: @"https://shimo-app-test.oss-cn-beijing.aliyuncs.com/resource/native-sdk/index.html",
            SHMDataHostKey: origins
        },
        @{
            SHMDataTitleKey: @"shimo.im 首页",
            SHMDataUrlKey: @"https://shimo.im/recent",
            SHMDataHostKey: origins
        },
        @{
            SHMDataTitleKey: @"shimo.im 上传",
            SHMDataUrlKey: @"https://shimo.im/forms/KlkKVg9bmah6Zbqd/fill",
            SHMDataHostKey: origins
        },
        @{
            SHMDataTitleKey: @"shimo.im 下载",
            SHMDataUrlKey: @"https://shimo.im/docs/N2A1M21oDRhb56AD",
            SHMDataHostKey: origins
        },
        @{
            SHMDataTitleKey: @"shimodev.com 首页",
            SHMDataUrlKey: @"https://shimodev.com/recent",
            SHMDataHostKey: @[@"https://shimodev.com", @"https://uploader.shimodev.com"]
        }
    ];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    
    [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
        make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
        make.left.equalTo(self.view.mas_safeAreaLayoutGuideLeft);
        make.right.equalTo(self.view.mas_safeAreaLayoutGuideRight);
    }];
}

#pragma mark - UITableViewDataSource


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SHMNativeSDK"];
    NSDictionary *data = self.datas[indexPath.row];
    cell.textLabel.text = data[SHMDataTitleKey];
    cell.detailTextLabel.text = data[SHMDataUrlKey];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *data = self.datas[indexPath.row];
    
    SHMWebViewController *viewController = [[SHMWebViewController alloc] init];
    viewController.url = [NSURL URLWithString:data[SHMDataUrlKey]];
    viewController.origins = data[SHMDataHostKey];
    [self.navigationController pushViewController:viewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
