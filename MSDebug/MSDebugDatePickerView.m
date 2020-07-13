//
//  MSDebugDatePickerView.m
//  MSDebug
//
//  Created by moses on 2020/7/3.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugDatePickerView.h"
#import <Masonry.h>

@interface MSDebugDatePickerView ()

@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UIView *barView;
@property (nonatomic, strong) UIButton *minButton;
@property (nonatomic, strong) UIButton *maxButton;
@property (nonatomic, assign) double min;
@property (nonatomic, assign) double max;

@end

@implementation MSDebugDatePickerView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = UIColor.clearColor;
        self.hidden = YES;
        [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideAction)]];
        [self addSubview:self.datePicker];
        [self.datePicker mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.height.offset(200);
            make.bottom.offset(245);
        }];
        [self addSubview:self.barView];
        [self.barView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.height.offset(45);
            make.bottom.equalTo(self.datePicker.mas_top);
        }];
        _formatter = [[NSDateFormatter alloc] init];
        _formatter.dateFormat = @"MM.dd HH:mm";
    }
    return self;
}

- (void)setMin:(double)min {
    _min = min ?: [NSDate date].timeIntervalSince1970;
    [_minButton setTitle:[NSString stringWithFormat:@"起:%@", [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_min]]] forState:(UIControlStateNormal)];
}

- (void)setMax:(double)max {
    _max = max ?: [NSDate date].timeIntervalSince1970;
    [_maxButton setTitle:[NSString stringWithFormat:@"止:%@", [_formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:_max]]] forState:(UIControlStateNormal)];
}

- (void)show {
    self.min = _minTime;
    self.max = _maxTime;
    [self minButtonAction:_minButton];
    _datePicker.maximumDate = NSDate.date;
    [_datePicker mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(0);
    }];
    self.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
        self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
    }];
}

- (void)hideAction {
    [_datePicker mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(245);
    }];
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
        self.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)clearAction {
    [self hideAction];
    _minTime = 0;
    _maxTime = 0;
    if (_callBack) {
        _callBack();
    }
}
#warning message
- (void)enterAction {
    [self hideAction];
    if (_min > _max) {
        //self.toast1 = @"起止时间设置有误";
        return;
    }
    _minTime = _min;
    _maxTime = _max;
    if (_callBack) {
        _callBack();
    }
}

- (void)dateChange {
    _datePicker.maximumDate = NSDate.date;
    if (_minButton.selected) {
        self.min = self.datePicker.date.timeIntervalSince1970;
    } else {
        self.max = self.datePicker.date.timeIntervalSince1970;
    }
}

- (void)minButtonAction:(UIButton *)button {
    button.selected = YES;
    _maxButton.selected = NO;
    _datePicker.maximumDate = NSDate.date;
    [_datePicker setDate:[NSDate dateWithTimeIntervalSince1970:_min] animated:YES];
}

- (void)maxButtonAction:(UIButton *)button {
    button.selected = YES;
    _minButton.selected = NO;
    _datePicker.maximumDate = NSDate.date;
    [_datePicker setDate:[NSDate dateWithTimeIntervalSince1970:_max] animated:YES];
}

- (NSString *)title {
    return [NSString stringWithFormat:@"%@\n%@", _minButton.currentTitle, _maxButton.currentTitle];
}

#pragma mark - 懒加载
#warning message
- (UIDatePicker *)datePicker {
    if (!_datePicker) {
        UIDatePicker *datePicker = [[UIDatePicker alloc] init];
        datePicker.backgroundColor = UIColor.whiteColor;
        datePicker.datePickerMode = UIDatePickerModeDateAndTime;
        //datePicker.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_GB"];
        datePicker.minimumDate = [NSDate dateWithTimeIntervalSince1970:0];
        [datePicker addTarget:self action:@selector(dateChange) forControlEvents:UIControlEventValueChanged];
        _datePicker = datePicker;
    }
    return _datePicker;
}

- (UIView *)barView {
    if (!_barView) {
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
        {
            UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
            [button setTitle:@"确定" forState:(UIControlStateNormal)];
            button.tintColor = [UIColor colorWithWhite:51/255.0 alpha:1];
            [view addSubview:button];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.right.top.bottom.offset(0);
                make.width.offset(70);
            }];
            [button addTarget:self action:@selector(enterAction) forControlEvents:(UIControlEventTouchUpInside)];
        }
        {
            UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
            [button setTitle:@"清空" forState:(UIControlStateNormal)];
            button.tintColor = [UIColor colorWithWhite:51/255.0 alpha:1];
            [view addSubview:button];
            [button mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.top.bottom.offset(0);
                make.width.offset(70);
            }];
            [button addTarget:self action:@selector(clearAction) forControlEvents:(UIControlEventTouchUpInside)];
        }
        [view addSubview:self.minButton];
        [_minButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.offset(0);
            make.left.offset(70);
            make.width.offset(UIScreen.mainScreen.bounds.size.width/2.0-70);
        }];
        [view addSubview:self.maxButton];
        [_maxButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.bottom.offset(0);
            make.right.offset(-70);
            make.width.offset(UIScreen.mainScreen.bounds.size.width/2.0-70);
        }];
        _barView = view;
    }
    return _barView;
}

- (UIButton *)minButton {
    if (!_minButton) {
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.tintColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        [button addTarget:self action:@selector(minButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        _minButton = button;
    }
    return _minButton;
}

- (UIButton *)maxButton {
    if (!_maxButton) {
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        button.tintColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        [button addTarget:self action:@selector(maxButtonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        _maxButton = button;
    }
    return _maxButton;
}

@end

#endif
