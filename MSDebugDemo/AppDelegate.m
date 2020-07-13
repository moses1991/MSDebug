//
//  AppDelegate.m
//  MSDebugDemo
//
//  Created by moses on 2020/6/30.
//  Copyright © 2020 moses. All rights reserved.
//

#import "AppDelegate.h"
#import "MSDebugManager.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifdef DEBUG
    MSDebugManager.sharedInstace.accountInfoKeyPath = @"TestUserModel.sharedInstace";
    MSDebugManager.sharedInstace.accountInfoKeys = @[@"userId", @"nickName", @"sex", @"avatar"];
    MSDebugModel *model = [MSDebugModel modelWithTitle:@"接口环境" options:@[@"https://production.moses.com", @"https://develop.moses.com", @"https://test.moses.com", @"https://local.moses.com"]];
    model.callBack = ^(id obj) {
        NSLog(@"111-%@", obj);
    };
    [MSDebugManager.sharedInstace addDebugModel:model];
    model = [MSDebugModel new];
    model.actionTitle = @"清空未读消息";
    model.callBack = ^(id obj) {
        NSLog(@"222-%@", obj);
    };
    [MSDebugManager.sharedInstace addDebugModel:model];
    [MSDebugManager.sharedInstace showDebugButtonOnWindow:self.window];
#endif
    return YES;
}

@end
