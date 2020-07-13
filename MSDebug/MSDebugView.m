//
//  MSDebugView.m
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugView.h"
#import "MSDebugManager.h"
#import <objc/runtime.h>
#import <Masonry.h>

static void msdebug_exchangeMethod(id className, SEL oldSelector, SEL newSelector) {
    if (className && oldSelector && newSelector) {
        Class cls = NSClassFromString([NSString stringWithFormat:@"%@", className]);
        if ([cls isKindOfClass:[NSObject class]]) {
            method_exchangeImplementations(class_getInstanceMethod(cls, oldSelector), class_getInstanceMethod(cls, newSelector));
        }
    }
}

@implementation UIView (MSDebugCategory)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        msdebug_exchangeMethod([UIView class], @selector(layoutSubviews), @selector(msdebug_layoutSubviews));
    });
}

- (void)msdebug_layoutSubviews {
    [self msdebug_layoutSubviews];
    self.msdebug_borderLayer.hidden = [[MSDebugManager.sharedInstace getCurrentSelectedWithTitle:@"view边框"] isEqualToString:@"显示"];
    self.msdebug_borderLayer.frame = self.bounds;
}

- (void)msdebug_showBorder:(BOOL)show {
    self.msdebug_borderLayer.hidden = !show;
    for (UIView *subView in self.subviews) {
        [subView msdebug_showBorder:show];
    }
}

- (CALayer *)msdebug_borderLayer {
    if ([self isDescendantOfView:[[UIApplication sharedApplication] valueForKey:@"_statusBarWindow"]]) {
        return nil;//状态栏不显示
    }
    CALayer *border = objc_getAssociatedObject(self, _cmd);
    if (!border) {
        border = [CALayer layer];
        border.borderColor = UIColor.redColor.CGColor;
        border.borderWidth = 0.3;
        border.hidden = YES;
        [self.layer addSublayer:border];
        objc_setAssociatedObject(self, _cmd, border, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return border;
}

- (void)setMsdebug_x:(CGFloat)msdebug_x {
    CGRect frame = self.frame;
    frame.origin.x = msdebug_x;
    self.frame = frame;
}

- (CGFloat)msdebug_x {
    return self.bounds.origin.x;
}

- (void)setMsdebug_y:(CGFloat)msdebug_y {
    CGRect frame = self.frame;
    frame.origin.y = msdebug_y;
    self.frame = frame;
}

- (CGFloat)msdebug_y {
    return self.bounds.origin.y;
}

@end

@implementation UIViewController (MSDebugCategory)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        msdebug_exchangeMethod([UIViewController class], @selector(viewDidAppear:), @selector(msdebug_viewDidAppear:));
    });
}

- (void)msdebug_viewDidAppear:(BOOL)animated {
    [self msdebug_viewDidAppear:animated];
    [self.view.window msdebug_showBorder:[[MSDebugManager.sharedInstace getCurrentSelectedWithTitle:@"view边框"] isEqualToString:@"隐藏"]];
}

@end

@implementation MSDebugView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        self.userInteractionEnabled = NO;
        UIView *view = [UIView new];
        [self addSubview:view];
        view.layer.cornerRadius = 5;
        view.layer.masksToBounds = YES;
        view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.offset(0);
        }];
        _imageView = [[UIImageView alloc] init];
        _imageView.layer.cornerRadius = 5;
        _imageView.layer.masksToBounds = YES;
        [self addSubview:_imageView];
        [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.offset(5);
            make.top.greaterThanOrEqualTo(@5);
            make.bottom.lessThanOrEqualTo(@-5);
        }];
        UIView *borderView = [UIView new];
        borderView.backgroundColor = UIColor.clearColor;
        borderView.layer.borderWidth = 1;
        borderView.layer.borderColor = UIColor.redColor.CGColor;
        [_imageView addSubview:borderView];
        [borderView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.centerY.offset(0);
            make.width.height.offset(0);
        }];
        _label = [[UILabel alloc] init];
        _label.textColor = UIColor.whiteColor;
        _label.font = [UIFont systemFontOfSize:13];
        _label.numberOfLines = 0;
        [self addSubview:_label];
        [_label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(_imageView.mas_right).offset(0);
            make.top.greaterThanOrEqualTo(@5);
            make.bottom.lessThanOrEqualTo(@-5);
            make.right.offset(-5);
        }];
        _probeLayer = [CALayer layer];
        _probeLayer.borderColor = UIColor.redColor.CGColor;
        _probeLayer.borderWidth = 0.3;
        [self.layer addSublayer:_probeLayer];
    }
    return self;
}

void msdebug_show_toast(NSString *toast) {
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    view.layer.cornerRadius = 4;
    view.layer.masksToBounds = YES;
    [UIApplication.sharedApplication.keyWindow addSubview:view];
    [view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.centerY.offset(0);
    }];
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:14];
    label.textColor = [UIColor whiteColor];
    label.text = toast;
    label.numberOfLines = 0;
    [view addSubview:label];
    [label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.offset(5);
        make.right.bottom.offset(-5);
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [view removeFromSuperview];
    });
}

@end

#endif
