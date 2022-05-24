//
//  SHMDownloadViewController.h
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/24.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/// 下载界面
///
/// TODO 请根据具体需求实现下载和预览
@interface SHMDownloadViewController : UIViewController

@property (nonnull, nonatomic, strong) NSURLResponse *response;

@end

NS_ASSUME_NONNULL_END
