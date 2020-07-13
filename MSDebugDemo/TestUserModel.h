//
//  TestUserModel.h
//  MSDebugDemo
//
//  Created by moses on 2020/7/9.
//  Copyright © 2020 moses. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TestUserModel : NSObject

@property (class, readonly, strong) TestUserModel *sharedInstace;
@property (nonatomic, copy) NSString *nickName; ///< 昵称
@property (nonatomic, copy) NSString *userId; ///< ID
@property (nonatomic, copy) NSString *sex; ///< 性别
@property (nonatomic, copy) NSString *avatar; ///< 头像

@end
