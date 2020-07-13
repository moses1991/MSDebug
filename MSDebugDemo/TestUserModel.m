//
//  TestUserModel.m
//  MSDebugDemo
//
//  Created by moses on 2020/7/9.
//  Copyright © 2020 moses. All rights reserved.
//

#import "TestUserModel.h"

@implementation TestUserModel

static TestUserModel * _instace;

+ (instancetype)sharedInstace {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[TestUserModel alloc] init];
    });
    return _instace;
}

- (NSString *)userId {
    return @"007";
}

- (NSString *)nickName {
    return @"测试";
}

- (NSString *)sex {
    return @"1";
}

- (NSString *)avatar {
    return @"https://ss0.bdstatic.com/70cFuHSh_Q1YnxGkpoWK1HF6hhy/it/u=491974561,2087397897&fm=26&gp=0.jpg";
}

@end
