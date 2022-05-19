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

@interface SHMViewController () <UITableViewDataSource, UITableViewDelegate>

@end

@implementation SHMViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"石墨 iOS SDK";
    
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
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SHMNativeSDK"];
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"demo";
        cell.detailTextLabel.text = @"https://shimo-app-test.oss-cn-beijing.aliyuncs.com/resource/native-sdk/index.html";
    } else {
        cell.textLabel.text = @"首页";
        cell.detailTextLabel.text = @"https://shimo.im/recent";
    }

    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *url = cell.detailTextLabel.text ?: @"";
    SHMWebViewController *viewController = [[SHMWebViewController alloc] initWithUrl: [NSURL URLWithString:url]];
    [self.navigationController pushViewController:viewController animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
