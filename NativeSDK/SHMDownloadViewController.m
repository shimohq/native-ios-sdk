//
//  SHMDownloadViewController.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/24.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMDownloadViewController.h"

#import <Masonry/Masonry.h>

@interface SHMDownloadViewController ()

@end

@implementation SHMDownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"下载";
    self.view.backgroundColor = [UIColor whiteColor];
    
    UILabel *namelabel = [[UILabel alloc] init];
    namelabel.textColor = [UIColor blackColor];
    namelabel.font = [UIFont systemFontOfSize:12];
    namelabel.textAlignment = NSTextAlignmentCenter;
    namelabel.numberOfLines = 0;
    [self.view addSubview:namelabel];
    
    UILabel *mimelabel = [[UILabel alloc] init];
    mimelabel.textColor = [UIColor blackColor];
    mimelabel.font = [UIFont systemFontOfSize:12];
    mimelabel.textAlignment = NSTextAlignmentCenter;
    mimelabel.numberOfLines = 0;
    [self.view addSubview:mimelabel];
    
    UILabel *urllabel = [[UILabel alloc] init];
    urllabel.textColor = [UIColor blackColor];
    urllabel.font = [UIFont systemFontOfSize:12];
    urllabel.textAlignment = NSTextAlignmentCenter;
    urllabel.numberOfLines = 0;
    [self.view addSubview:urllabel];
    
    [namelabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(mimelabel.mas_top).offset(-10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    [mimelabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.view);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    [urllabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(mimelabel.mas_bottom).offset(10);
        make.left.equalTo(self.view).offset(20);
        make.right.equalTo(self.view).offset(-20);
    }];
    
    namelabel.text = self.response.suggestedFilename;
    mimelabel.text = self.response.MIMEType;
    urllabel.text = self.response.URL.absoluteString;
}

@end
