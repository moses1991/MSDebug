//
//  MSDebugView.h
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import <UIKit/UIKit.h>

@interface UIView (MSDebugCategory)

- (void)msdebug_showBorder:(BOOL)show;
@property (nonatomic, assign) CGFloat msdebug_x;
@property (nonatomic, assign) CGFloat msdebug_y;

@end

@interface UIViewController (MSDebugCategory)

@end

@interface MSDebugView : UIView

@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *label;
@property (nonatomic, strong, readonly) CALayer *probeLayer;

void msdebug_show_toast(NSString *toast);

@end

#endif
