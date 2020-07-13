//
//  MSDebugDatePickerView.h
//  MSDebug
//
//  Created by moses on 2020/7/3.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import <UIKit/UIKit.h>

@interface MSDebugDatePickerView : UIView

@property (nonatomic, assign, readonly) double minTime;
@property (nonatomic, assign, readonly) double maxTime;
@property (nonatomic, strong, readonly) NSDateFormatter *formatter;
@property (nonatomic, copy) void (^callBack)(void);
- (void)show;
- (NSString *)title;

@end

#endif
