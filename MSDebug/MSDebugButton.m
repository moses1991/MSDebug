//
//  MSDebugButton.m
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugButton.h"
#import "MSDebugView.h"
#import <Masonry.h>
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT  [UIScreen mainScreen].bounds.size.height
#define iPhoneX        ((SCREEN_HEIGHT / SCREEN_WIDTH < 0.5) || (SCREEN_WIDTH / SCREEN_HEIGHT < 0.5))

@interface MSDebugButton () {
    CGFloat _ratio;
}

@property (nonatomic, assign) CGPoint diffPoint;
@property (nonatomic, strong) UILabel *verticalLabel;
@property (nonatomic, strong) UILabel *horizontalLabel;
@property (nonatomic, strong) MSDebugView *desView;
@property (nonatomic, strong) NSMutableArray *views;
@property (nonatomic, assign) BOOL left;
@property (nonatomic, assign) BOOL up;
@property (nonatomic, strong) UIImage *cutImage;

@end

@implementation MSDebugButton

static const CGFloat initialY = 300.0;

- (instancetype)init {
    self = [super init];
    if (self) {
        _left = YES;
        _views = [NSMutableArray arrayWithCapacity:10];
        UIView *verticalLine = [UIView new];
        verticalLine.backgroundColor = UIColor.blackColor;
        verticalLine.hidden = YES;
        [self addSubview:verticalLine];
        verticalLine.frame = CGRectMake(0, 0, 0.5, SCREEN_HEIGHT * 2);
        verticalLine.center = CGPointMake(25, 25);
        
        UILabel *verticalLabel = [UILabel new];
        verticalLabel.font = [UIFont systemFontOfSize:13];
        verticalLabel.textColor = UIColor.blackColor;
        [verticalLine addSubview:verticalLabel];
        _verticalLabel = verticalLabel;
        
        UIView *horizontalLine = [UIView new];
        horizontalLine.backgroundColor = UIColor.blackColor;
        horizontalLine.hidden = YES;
        [self addSubview:horizontalLine];
        horizontalLine.frame = CGRectMake(0, 0, SCREEN_HEIGHT * 2, 0.5);
        horizontalLine.center = CGPointMake(25, 25);
        
        UILabel *horizontalLabel = [UILabel new];
        horizontalLabel.font = [UIFont systemFontOfSize:13];
        horizontalLabel.textColor = UIColor.blackColor;
        [horizontalLine addSubview:horizontalLabel];
        _horizontalLabel = horizontalLabel;
        
        _desView = [MSDebugView new];
        [self addSubview:_desView];
        [_desView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_bottom);
            make.centerX.offset(0).priorityLow();
            make.right.lessThanOrEqualTo(self.mas_right);
            make.width.lessThanOrEqualTo(@(SCREEN_WIDTH-30));
        }];
        
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"MSDebug" ofType:@"bundle"]];
        NSString *path = [bundle pathForResource:[NSString stringWithFormat:@"debug@%.0fx", UIScreen.mainScreen.scale] ofType:@"png"];
        [button setImage:[[UIImage imageWithContentsOfFile:path] imageWithRenderingMode:(UIImageRenderingModeAlwaysOriginal)] forState:(UIControlStateNormal)];
        button.frame = CGRectMake(0, 0, 50, 50);
        [self addSubview:button];
        _button = button;
        
        [verticalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.offset(0);
            make.top.equalTo(self.button).offset(SCREEN_HEIGHT/2.0+initialY/2.0);
        }];
        [horizontalLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(0);
            make.left.equalTo(self.button).offset(SCREEN_WIDTH/2.0);
        }];
        
        [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)]];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bringFront) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordRatio) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetFrame) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    }
    return self;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self resetSubviewsFrame];
}

- (void)setCenter:(CGPoint)center {
    [super setCenter:center];
    [self resetSubviewsFrame];
}

- (void)setShowBorder:(BOOL)showBorder {
    _showBorder = showBorder;
    [self.window msdebug_showBorder:showBorder];
}

- (void)resetSubviewsFrame {
    CGPoint point = [self convertPoint:CGPointMake(25, 25) toView:nil];
    _verticalLabel.text = [NSString stringWithFormat:@"%.1f", point.x];
    _horizontalLabel.text = [NSString stringWithFormat:@"%.1f", point.y];
    BOOL left = point.x > SCREEN_WIDTH / 2.0;
    BOOL up = point.y > SCREEN_HEIGHT / 2.0;
    [_verticalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        left ? make.right.offset(0) : make.left.offset(0);
        make.top.equalTo(self.button).offset(up?(-point.y/2.0):(SCREEN_HEIGHT/2.0 - point.y/2.0));
    }];
    [_horizontalLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.button).offset(left?(-point.x/2.0):(SCREEN_WIDTH/2.0 - point.x/2.0));
        up ? make.bottom.offset(0) : make.top.offset(0);
    }];
    if (_left != left) {
        _left = left;
        [_desView mas_remakeConstraints:^(MASConstraintMaker *make) {
            up ? make.bottom.equalTo(self.mas_top).offset(-20) : make.top.equalTo(self.mas_bottom).offset(20);
            make.centerX.offset(0).priorityLow();
            left ? make.right.lessThanOrEqualTo(self.superview.mas_right) : make.left.greaterThanOrEqualTo(self.superview.mas_left);
            make.width.lessThanOrEqualTo(@(SCREEN_WIDTH-30));
        }];
    }
    if (_up != up) {
        _up = up;
        [_desView mas_remakeConstraints:^(MASConstraintMaker *make) {
            up ? make.bottom.equalTo(self.mas_top).offset(-20) : make.top.equalTo(self.mas_bottom).offset(20);
            make.centerX.offset(0).priorityLow();
            left ? make.right.lessThanOrEqualTo(self.superview.mas_right) : make.left.greaterThanOrEqualTo(self.superview.mas_left);
            make.width.lessThanOrEqualTo(@(SCREEN_WIDTH-30));
        }];
    }
    [self layoutIfNeeded];

    if (_showProbeViewInfo) {
        [_views removeAllObjects];
        [self hitTest:self.window point:self.center];
        UIView *topView = _views.lastObject;
        _desView.label.text = [_views.description substringWithRange:(NSMakeRange(2, _views.description.length-4))];
        _desView.probeLayer.frame = [topView convertRect:topView.bounds toView:_desView];
        [_views removeAllObjects];
    }
    if (_showMagnifier) {
        CGImageRef imageRef = CGImageCreateWithImageInRect(self.cutImage.CGImage, CGRectMake(self.center.x * UIScreen.mainScreen.scale - 50, self.center.y * UIScreen.mainScreen.scale - 50, 100, 100));
        _desView.imageView.image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        _desView.label.text = [self colorAtPoint:self.center inImage:self.cutImage];
    } else {
        _desView.imageView.image = nil;
    }
    _desView.hidden = !_showMagnifier && !_showProbeViewInfo;
}

- (NSString *)colorAtPoint:(CGPoint)point inImage:(UIImage *)image {
    if (!image || !CGRectContainsPoint(CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), point)) {
        return nil;
    }
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char pixelData[4] = {0, 0, 0, 0};
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextSetBlendMode(context, kCGBlendModeCopy);
    CGContextTranslateCTM(context, -trunc(point.x), trunc(point.y)-image.size.height);
    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), image.CGImage);
    CGContextRelease(context);
    NSString *color = [NSString stringWithFormat:@"%02x%02x%02x", pixelData[0], pixelData[1], pixelData[2]];
    unsigned long r = strtoul([[color substringWithRange:NSMakeRange(0, 2)] UTF8String], 0, 16);
    unsigned long g = strtoul([[color substringWithRange:NSMakeRange(2, 2)] UTF8String], 0, 16);
    unsigned long b = strtoul([[color substringWithRange:NSMakeRange(4, 2)] UTF8String], 0, 16);
    return [NSString stringWithFormat:@"%@\n%ld,%ld,%ld", color.uppercaseString, r, g, b];
}

- (void)hitTest:(UIView *)view point:(CGPoint)point {
    if ([view isKindOfClass:[UIScrollView class]]) {
        point.x += ((UIScrollView*)view).contentOffset.x;
        point.y += ((UIScrollView*)view).contentOffset.y;
    }
    if ([view pointInside:point withEvent:nil] && (!view.hidden) && (view.alpha >= 0.01f) && ![view isDescendantOfView:self]) {
        [_views addObject:view];
        for (UIView *subView in view.subviews) {
            [self hitTest:subView point:CGPointMake(point.x - subView.msdebug_x, point.y - subView.msdebug_y)];
        }
    }
}

- (void)setShowRuler:(BOOL)showRuler {
    _showRuler = showRuler;
    _verticalLabel.superview.hidden = !showRuler;
    _horizontalLabel.superview.hidden = !showRuler;
    [self resetSelfFrame];
}

- (void)setShowMagnifier:(BOOL)showMagnifier {
    _showMagnifier = showMagnifier;
    [self resetSelfFrame];
}

- (void)setShowProbeViewInfo:(BOOL)showProbeViewInfo {
    _showProbeViewInfo = showProbeViewInfo;
    [self resetSelfFrame];
}

- (void)resetSelfFrame {
    if (!(_showRuler||_showMagnifier||_showProbeViewInfo)) {
        CGFloat x = self.msdebug_x;
        if (x < SCREEN_WIDTH / 2.0) {
            x = 0;
            if (iPhoneX && SCREEN_WIDTH > SCREEN_HEIGHT) {
                x = 44;
            }
        } else {
            x = SCREEN_WIDTH - self.bounds.size.width;
        }
        [UIView animateWithDuration:0.25 animations:^{
            self.msdebug_x = x;
        }];
    }
}

- (void)bringFront {
    [self.superview bringSubviewToFront:self];
}

- (void)recordRatio {
    _ratio = self.msdebug_y/SCREEN_HEIGHT;
}

- (void)resetFrame {
    if (self.msdebug_x) {
        self.msdebug_x = SCREEN_WIDTH-50;
    }
    self.msdebug_y = MIN((_ratio*SCREEN_HEIGHT), (SCREEN_HEIGHT-50));
}

- (void)pan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        CGPoint panPoint = [pan locationInView:pan.view.superview];
        _diffPoint = CGPointMake(self.center.x-panPoint.x, self.center.y-panPoint.y);
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint panPoint = [pan locationInView:pan.view.superview];
        pan.view.center = CGPointMake(panPoint.x+_diffPoint.x, panPoint.y+_diffPoint.y);
    } else if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled) {
        if (_showRuler||_showMagnifier||_showProbeViewInfo) {
            CGFloat cx = pan.view.center.x;
            CGFloat cy = pan.view.center.y;
            cx = MAX(0, MIN(cx, SCREEN_WIDTH));
            CGFloat statusBar = [UIApplication sharedApplication].statusBarFrame.size.height;
            cy = MAX(statusBar, MIN(cy, SCREEN_HEIGHT - (iPhoneX ? 34 : 0)));
            [UIView animateWithDuration:0.25 animations:^{
                pan.view.center = CGPointMake(cx, cy);
            } completion:^(BOOL finished) {
                self.cutImage = nil;
            }];
            return;
        }
        CGFloat x = pan.view.frame.origin.x;
        CGFloat y = pan.view.frame.origin.y;
        CGFloat width = pan.view.frame.size.width;
        CGFloat height = pan.view.frame.size.height;
        if (y < 0) {
            y = 0;
        } else if (y + height > SCREEN_HEIGHT) {
            y = SCREEN_HEIGHT - height;
        }
        if (pan.view.center.x < SCREEN_WIDTH / 2.0) {
            x = 0;
            if (iPhoneX && SCREEN_WIDTH > SCREEN_HEIGHT) {
                x = 44;
            }
        } else {
            x = SCREEN_WIDTH - width;
        }
        [UIView animateWithDuration:0.25 animations:^{
            pan.view.frame = CGRectMake(x, y, width, height);
        }];
    }
}

- (UIImage *)cutImage {
    if (!_cutImage) {
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen.bounds.size, NO, UIScreen.mainScreen.scale);
        [self.window.layer renderInContext:UIGraphicsGetCurrentContext()];
        _cutImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return _cutImage;
}

@end

#endif
