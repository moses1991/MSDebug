//
//  MSDebugLogViewController.m
//  MSDebug
//
//  Created by moses on 2020/7/1.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugLogViewController.h"
#import "MSDebugDatePickerView.h"
#import "MSDebugHook.h"
#import "MSDebugView.h"
#import <Masonry.h>
#import <FMDB.h>

@interface MSDebugLogModel : NSObject

@property (nonatomic, assign) long ID;
@property (nonatomic, assign) double time;
@property (nonatomic, copy) NSString *str;

@end

@implementation MSDebugLogModel

@end

@interface MSDebugLogTool : NSObject

@end

@interface MSDebugLogTool ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end

@implementation MSDebugLogTool

static void (*ns_NSLog)(NSString *format, ...);
void ms_NSLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    [[MSDebugLogTool shareInstance] insertData:message];
    va_end(args);
    ns_NSLog(@"%@", message);
}

static int (*ns_printf)(const char * __restrict c, ...);
int ms_printf(const char * __restrict c, ...) {
    va_list args;
    va_start(args, c);
    NSString *message = [[NSString alloc] initWithFormat:[NSString stringWithCString:c encoding:(NSUTF8StringEncoding)] arguments:args];
    [[MSDebugLogTool shareInstance] insertData:message];
    va_end(args);
    return ns_printf("%s", message.UTF8String);
}

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        msdebug_rebind_symbols((struct msdebug_rebinding[1]){{"printf", ms_printf, (void *)&ns_printf}}, 1);
        msdebug_rebind_symbols((struct msdebug_rebinding[1]){{"NSLog", ms_NSLog, (void *)&ns_NSLog}}, 1);
    });
}

static id shareInstance;

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[self alloc] init];
    });
    return shareInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        _dbQueue = [FMDatabaseQueue databaseQueueWithPath:[NSString stringWithFormat:@"%@/Documents/msDebugLog.sqlite", NSHomeDirectory()]];
        [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
            NSAssert(db.open, @"数据库创建失败");
            NSAssert([db executeUpdate:@"create table if not exists logstr(id integer primary key autoincrement, time double, str text)" values:nil error:nil], @"数据表创建失败");
            [db close];
        }];
    }
    return self;
}

- (void)insertData:(NSString *)str {
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (db.open) {
            NSString *sql = [NSString stringWithFormat:@"insert into logstr(time, str) values(%f,'%@')", [NSDate date].timeIntervalSince1970, str];
            bool result = [db executeUpdate:sql values:nil error:nil];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!result) {
                    msdebug_show_toast(@"有打印数据插入失败");
                }
            });
        }
        [db close];
    }];
}

- (NSMutableArray *)selectDataFrom:(double)from to:(double)to search:(NSString *)search {
    NSMutableArray *arr = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (db.open) {
            NSString *sql = @"select * from logstr";
            if (from && to && from <= to) {
                sql = [NSString stringWithFormat:@"%@ where time >= %f and time <= %f", sql, from, to];
                if (search.length) {
                    sql = [NSString stringWithFormat:@"%@ and str like '%%%@%%'", sql, search];
                }
            } else if (search.length) {
                sql = [NSString stringWithFormat:@"%@ where str like '%%%@%%'", sql, search];
            }
            FMResultSet *rs = [db executeQuery:sql];
            while (rs.next) {
                MSDebugLogModel *model = [MSDebugLogModel new];
                model.ID = [rs intForColumnIndex:0];
                model.time = [rs doubleForColumnIndex:1];
                model.str = [rs stringForColumnIndex:2];
                [arr addObject:model];
            }
        }
        [db close];
    }];
    return arr;
}

- (void)deleteWithID:(long)ID before:(BOOL)before {
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (db.open) {
            NSString *sql = @"delete from logstr";
            if (ID) {
                NSString *symbol = before ? @"<=" : @"=";
                sql = [NSString stringWithFormat:@"%@ where id %@ %ld", sql, symbol, ID];
            }
            bool result = [db executeUpdate:sql values:nil error:nil];
            if (!result) {
                msdebug_show_toast(@"删除失败");
            }
        }
        [db close];
    }];
}

- (void)deleteWithFrom:(double)from to:(double)to str:(NSString *)str {
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        if (db.open) {
            NSString *sql = @"delete from logstr";
            if (from && to && from <= to) {
                sql = [NSString stringWithFormat:@"%@ where time >= %f and time <= %f", sql, from, to];
                if (str.length) {
                    sql = [NSString stringWithFormat:@"%@ and str like '%%%@%%'", sql, str];
                }
            } else if (str.length) {
                sql = [NSString stringWithFormat:@"%@ where str like '%%%@%%'", sql, str];
            }
            bool result = [db executeUpdate:sql values:nil error:nil];
            if (!result) {
                msdebug_show_toast(@"删除失败");
            }
        }
        [db close];
    }];
}

@end

@interface MSDebugLogViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray <MSDebugLogModel *>*dataArray;
@property (nonatomic, strong) UITextField *search;
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, copy) NSString *searchStr;
@property (nonatomic, strong) MSDebugDatePickerView *picker;

@end

@implementation MSDebugLogViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)keyboardWillChange:(NSNotification *)no {
    CGFloat y = [no.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].origin.y;
    [self.tableView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.bottom.offset(y - UIScreen.mainScreen.bounds.size.height);
    }];
    [UIView animateWithDuration:0.25 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1];
    [self.view addSubview:self.button];
    [self.button mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.offset(-12);
        make.top.offset([UIApplication sharedApplication].statusBarFrame.size.height);
        make.height.offset(44);
        make.width.priorityHigh();
    }];
    [self.view addSubview:self.search];
    [self.search mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.offset(12);
        make.top.offset([UIApplication sharedApplication].statusBarFrame.size.height + 5);
        make.height.offset(34);
        make.right.equalTo(self.button.mas_left).offset(-10);
        make.width.priorityLow();
    }];
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.offset(0);
        make.top.offset([UIApplication sharedApplication].statusBarFrame.size.height + 44);
    }];
    [self.view addSubview:self.picker];
    [self.picker mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.dataArray = [[MSDebugLogTool shareInstance] selectDataFrom:0 to:0 search:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView reloadData];
        });
    });
    
    [self.button addTarget:self action:@selector(showAction) forControlEvents:(UIControlEventTouchUpInside)];
    __weak typeof(self)weakSelf = self;
    self.picker.callBack = ^{
        if (weakSelf.picker.minTime && weakSelf.picker.maxTime) {
            [weakSelf.button setTitle:[weakSelf.picker title] forState:(UIControlStateNormal)];
        } else {
            [weakSelf.button setTitle:@" 筛选时间段 " forState:(UIControlStateNormal)];
        }
        [weakSelf reloadData];
    };
    self.tableView.contentOffset = CGPointMake(0, -self.tableView.contentInset.top);
    
    [self.view addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self.navigationController.interactivePopGestureRecognizer.delegate action:NSSelectorFromString(@"handleNavigationTransition:")]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)showAction {
    [self.search resignFirstResponder];
    [self.picker show];
}

- (BOOL)textFieldShouldClear:(UITextField *)textField {
    textField.text = nil;
    _searchStr = nil;
    [self reloadData];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![self.searchStr isEqualToString:textField.text]) {
            self.searchStr = textField.text;
            [self reloadData];
        }
    });
    return YES;
}

- (void)reloadData {
    self.dataArray = [[MSDebugLogTool shareInstance] selectDataFrom:_picker.minTime to:_picker.maxTime search:_searchStr];
    [self.tableView reloadData];
}

#pragma mark - tableView代理方法

static NSString * cellIdentifier = @"logCell";

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleDefault) reuseIdentifier:cellIdentifier];
    }
    cell.contentView.transform = CGAffineTransformMakeRotation(M_PI);
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.separatorInset = UIEdgeInsetsMake(0, 12, 0, 12);
    UITextView *textView = [cell.contentView viewWithTag:2345];
    UILabel *time = [cell.contentView viewWithTag:3456];
    if (!textView) {
        textView = [[UITextView alloc] init];
        textView.backgroundColor = UIColor.whiteColor;
        textView.tag = 2345;
        textView.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        textView.scrollEnabled = NO;
        textView.editable = NO;
        [cell.contentView addSubview:textView];
        [textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.offset(5);
            make.left.offset(10);
            make.right.offset(-10);
            make.bottom.offset(-5);
        }];
        time = [[UILabel alloc] init];
        time.tag = 3456;
        time.font = [UIFont systemFontOfSize:12 weight:(UIFontWeightHeavy)];
        time.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        [cell.contentView addSubview:time];
        [time mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.offset(-12);
            make.bottom.offset(-12);
        }];
    }
    MSDebugLogModel *model = self.dataArray[self.dataArray.count - 1 - indexPath.row];
    [textView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchAction:)]];
    textView.text = model.str;
    time.text = [self.picker.formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:model.time]];
    return cell;
}

- (void)touchAction:(UITapGestureRecognizer *)tap {
    UITableViewCell *cell = (UITableViewCell *)tap.view.superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    MSDebugLogModel *model = self.dataArray[self.dataArray.count - 1 - indexPath.row];
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"删除数据" message:nil preferredStyle:(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet)];
    NSArray *a = @[@"删除此条数据", @"删除当前检索结果数据", @"删除此条数据之前的所有数据", @"删除所有数据"];
    __weak typeof(self)weakSelf = self;
    for (NSString *s in a) {
        [alertController addAction:[UIAlertAction actionWithTitle:s style:(UIAlertActionStyleDefault) handler:^(UIAlertAction * _Nonnull action) {
            [weakSelf deleteDataWithIndex:[a indexOfObject:s] model:model];
        }]];
    }
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:(UIAlertActionStyleCancel) handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteDataWithIndex:(NSInteger)index model:(MSDebugLogModel *)model {
    switch (index) {
        case 0:
            [[MSDebugLogTool shareInstance] deleteWithID:model.ID before:NO];
            break;
        case 1:
            [[MSDebugLogTool shareInstance] deleteWithFrom:_picker.minTime to:_picker.maxTime str:_searchStr];
            break;
        case 2:
            [[MSDebugLogTool shareInstance] deleteWithID:model.ID before:YES];
            break;
        case 3:
            [[MSDebugLogTool shareInstance] deleteWithID:0 before:NO];
            break;
        default:
            break;
    }
    [self reloadData];
}

#pragma mark - 懒加载

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] init];
        CGFloat top = 0;
        if (@available(iOS 11, *)) {
            tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            CGSize size = UIScreen.mainScreen.bounds.size;
            if (size.width / size.height < 0.5) {
                UIEdgeInsets inset = tableView.contentInset;
                inset.top = 54;
                tableView.contentInset = inset;
                top = 34;
            }
        }
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:(CGRectZero)];
        tableView.transform = CGAffineTransformMakeRotation(M_PI);
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(top, 0, -top, UIScreen.mainScreen.bounds.size.width - 8);
        tableView.delegate = self;
        tableView.dataSource = self;
        tableView.estimatedRowHeight = 300;
        _tableView = tableView;
    }
    return _tableView;
}

- (UITextField *)search {
    if (!_search) {
        UITextField *textField = [[UITextField alloc] init];
        textField.clearButtonMode = UITextFieldViewModeAlways;
        textField.placeholder = @"输入字符可检索";
        textField.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        textField.font = [UIFont systemFontOfSize:14];
        textField.delegate = self;
        _search = textField;
    }
    return _search;
}

- (UIButton *)button {
    if (!_button) {
        UIButton *button = [UIButton buttonWithType:(UIButtonTypeSystem)];
        [button setTitle:@" 筛选时间段 " forState:(UIControlStateNormal)];
        button.tintColor = [UIColor colorWithWhite:51/255.0 alpha:1];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        button.titleLabel.numberOfLines = 0;
        _button = button;
    }
    return _button;
}

- (MSDebugDatePickerView *)picker {
    if (!_picker) {
        _picker = [MSDebugDatePickerView new];
    }
    return _picker;
}

@end

#endif
