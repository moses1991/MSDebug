//
//  MSDebugManager.m
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#import "MSDebugManager.h"
#import "MSDebugButton.h"
#import "MSDebugView.h"

@implementation MSDebugModel

+ (MSDebugModel *)modelWithTitle:(NSString *)title className:(NSString *)className {
    MSDebugModel *model = [MSDebugModel new];
    model.actionTitle = title;
    model.vcClassName = className;
    return model;
}
+ (MSDebugModel *)modelWithTitle:(NSString *)title options:(NSArray <NSString *>*)options {
    MSDebugModel *model = [MSDebugModel new];
    model.actionTitle = title;
    model.options = options;
    return model;
}

@end

#ifdef DEBUG

@interface MSDebugManager ()

@property (nonatomic, strong) NSMutableArray <MSDebugModel *>*dataArray; ///< 数据源
@property (nonatomic, strong) NSMutableDictionary *savedData; ///< 保存的数据
@property (nonatomic, copy) NSString *savedDataPath; ///< 数据保存路径
@property (nonatomic, strong) MSDebugButton *button; ///< 调试按钮

@end

@implementation MSDebugManager

static MSDebugManager * _instace;

+ (instancetype)sharedInstace {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instace = [[MSDebugManager alloc] init];
        _instace.savedDataPath = [NSHomeDirectory() stringByAppendingString:@"/Documents/msDebug"];
        [_instace savedData];
    });
    return _instace;
}

/// 增加多个自定义功能
- (void)addDebugModels:(NSArray <MSDebugModel *>*)models {
    for (MSDebugModel *model in models) {
        [self addDebugModel:model];
    }
}
/// 增加单个自定义功能
- (void)addDebugModel:(MSDebugModel *)model {
    if ([model isKindOfClass:[MSDebugModel class]]) {
        [self.dataArray insertObject:model atIndex:0];
        if (model.options.count > 1) {
            if (![_savedData objectForKey:model.actionTitle]) {
                [_savedData setObject:model.options.firstObject forKey:model.actionTitle];
            }
        }
    }
}
/// 将调试按钮添加到window上
- (void)showDebugButtonOnWindow:(UIWindow *)window {
    [window addSubview:self.button];
    self.button.frame = CGRectMake(UIScreen.mainScreen.bounds.size.width - 50, 300, 50, 50);
}

- (void)buttonAction {
    UIViewController *topVC = _button.window.rootViewController;
    while (topVC.presentedViewController) {
        topVC = topVC.presentedViewController;
    }
    if ([topVC isKindOfClass:[UIAlertController class]]) {
        return;
    }
    UINavigationController *vc;
    if ([topVC isKindOfClass:[UITabBarController class]]) {
        vc = ((UITabBarController *)topVC).selectedViewController;
    } else {
        vc = (UINavigationController *)topVC;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
    for (MSDebugModel *model in self.dataArray) {
        NSString *title = model.actionTitle;
        if (model.options.count == 2) {
            title = [NSString stringWithFormat:@"%@%@", self.savedData[title], title];
        } else if (model.options.count > 2) {
            title = [NSString stringWithFormat:@"%@:%@", title, self.savedData[title]];
        }
        [alertController addAction:[UIAlertAction actionWithTitle:title style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            if (model.vcClassName.length) {
                if ([vc isKindOfClass:[UINavigationController class]]) {
                    [vc pushViewController:[NSClassFromString(model.vcClassName) new] animated:YES];
                } else {
                    msdebug_show_toast(@"没有导航栏不能push页面");
                }
                if (model.callBack) {
                    model.callBack(nil);
                }
            } else if (model.options.count == 2) {
                NSString *old = self.savedData[model.actionTitle];
                if ([model.options indexOfObject:old]) {
                    self.savedData[model.actionTitle] = model.options[0];
                } else {
                    self.savedData[model.actionTitle] = model.options[1];
                }
                NSDictionary *dict = @{@"view边框":@"showBorder",
                                       @"view探测":@"showProbeViewInfo",
                                       @"对齐标尺":@"showRuler",
                                       @"取色功能":@"showMagnifier"};
                if ([dict.allKeys containsObject:model.actionTitle]) {
                    [self.button setValue:@(![model.options indexOfObject:old]) forKey:dict[model.actionTitle]];
                }
                [self.savedData writeToFile:self.savedDataPath atomically:YES];
                if (model.callBack) {
                    model.callBack(old);
                }
            } else if (model.options.count > 2) {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:model.actionTitle message:nil preferredStyle:(UIAlertControllerStyleActionSheet)];
                for (NSString *option in model.options) {
                    [alertController addAction:[UIAlertAction actionWithTitle:option style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
                        self.savedData[model.actionTitle] = option;
                        [self.savedData writeToFile:self.savedDataPath atomically:YES];
                        if (model.callBack) {
                            model.callBack(option);
                        }
                    }]];
                }
                [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
                [topVC presentViewController:alertController animated:YES completion:nil];
            } else {
                if (model.callBack) {
                    model.callBack(nil);
                }
            }
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
    [topVC presentViewController:alertController animated:YES completion:nil];
}

- (NSString *)getCurrentSelectedWithTitle:(NSString *)title {
    return _savedData[title];
}

- (NSMutableArray *)dataArray {
    if (!_dataArray) {
        _dataArray = [NSMutableArray array];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"app基本信息" className:@"MSDebugAuthorityViewController"]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"历史打印信息" className:@"MSDebugLogViewController"]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"浏览沙盒文件" className:@"MSDebugSandboxViewController"]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"view边框" options:@[@"显示",@"隐藏"]]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"view探测" options:@[@"开启",@"关闭"]]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"对齐标尺" options:@[@"显示",@"隐藏"]]];
        [_dataArray addObject:[MSDebugModel modelWithTitle:@"取色功能" options:@[@"开启",@"关闭"]]];
    }
    return _dataArray;
}

- (NSMutableDictionary *)savedData {
    if (!_savedData) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:_savedDataPath]) {
            _savedData = [NSMutableDictionary dictionaryWithContentsOfFile:_savedDataPath];
            [_savedData setObject:@"显示" forKey:@"view边框"];
            [_savedData setObject:@"开启" forKey:@"view探测"];
            [_savedData setObject:@"显示" forKey:@"对齐标尺"];
            [_savedData setObject:@"开启" forKey:@"取色功能"];
        } else {
            _savedData = [NSMutableDictionary dictionary];
            for (MSDebugModel *model in self.dataArray) {
                if (model.options.count > 1) {
                    [_savedData setObject:model.options.firstObject forKey:model.actionTitle];
                }
            }
            [_savedData writeToFile:_savedDataPath atomically:YES];
        }
    }
    return _savedData;
}

- (MSDebugButton *)button {
    if (!_button) {
        _button = [[MSDebugButton alloc] init];
        [_button.button addTarget:self action:@selector(buttonAction) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _button;
}

@end

#else

@implementation MSDebugManager

+ (instancetype)sharedInstace {return nil;}
/// 增加多个自定义功能
- (void)addDebugModels:(NSArray <MSDebugModel *>*)models {}
/// 增加单个自定义功能
- (void)addDebugModel:(MSDebugModel *)model {}
/// 将调试按钮添加到window上
- (void)showDebugButtonOnWindow:(UIWindow *)window {}
/// 通过标题获取当前选中的选项
- (NSString *)getCurrentSelectedWithTitle:(NSString *)title {return @"";}

@end

#endif
