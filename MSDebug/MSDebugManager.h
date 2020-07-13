//
//  MSDebugManager.h
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIWindow;

@interface MSDebugModel : NSObject

@property (nonatomic, copy) NSString *vcClassName; ///< 控制器类名
@property (nonatomic, copy) NSString *actionTitle; ///< 弹窗标题
@property (nonatomic, copy) NSArray <NSString *>*options; ///< 每个标题可选的选项
@property (nonatomic, copy) void (^callBack)(id obj); ///< 点击回调
+ (MSDebugModel *)modelWithTitle:(NSString *)title className:(NSString *)className;
+ (MSDebugModel *)modelWithTitle:(NSString *)title options:(NSArray <NSString *>*)options;

@end

@interface MSDebugManager : NSObject

@property (class, readonly, strong) MSDebugManager *sharedInstace;
@property (nonatomic, copy) NSString *accountInfoKeyPath; ///< 账号信息路径
@property (nonatomic, copy) NSArray <NSString *>*accountInfoKeys; ///< 账号信息属性
/// 增加多个自定义功能
- (void)addDebugModels:(NSArray <MSDebugModel *>*)models;
/// 增加单个自定义功能
- (void)addDebugModel:(MSDebugModel *)model;
/// 将调试按钮添加到window上
- (void)showDebugButtonOnWindow:(UIWindow *)window;
/// 通过标题获取当前选中的选项
- (NSString *)getCurrentSelectedWithTitle:(NSString *)title;

@end


