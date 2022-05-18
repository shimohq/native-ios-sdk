//
//  SHMWindow.m
//  NativeSDK
//
//  Created by Bell Zhong on 2022/5/18.
//  Copyright © 2022 shimo.im. All rights reserved.
//

#import "SHMWindow.h"
#import "SHMViewController.h"

@implementation SHMWindow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initWindow];
    }
    return self;
}

- (instancetype)initWithWindowScene:(UIWindowScene *)windowScene {
    self = [super initWithWindowScene:windowScene];
    if (self) {
        [self initWindow];
    }
    return self;
}

- (void)initWindow {
    self.backgroundColor = [UIColor whiteColor];
    
    SHMViewController *viewController = [[SHMViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    self.rootViewController = navigationController;
}

@end
