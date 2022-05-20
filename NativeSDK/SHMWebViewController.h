//
//  SHMWebViewController.h
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SHMWebViewController : UIViewController

@property (nonnull, nonatomic, strong, readonly) NSURL *url;
@property (nonnull, nonatomic, strong, readonly) NSString *host;

- (instancetype)initWithUrl:(nonnull NSURL *)url;
- (instancetype)initWithUrl:(nonnull NSURL *)url host:(NSString *)host;

@end

NS_ASSUME_NONNULL_END
