//
//  MSDebugSandboxViewController.m
//  MSDebug
//
//  Created by moses on 2020/7/3.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugSandboxViewController.h"
#import <WebKit/WebKit.h>
#import <AVKit/AVKit.h>
#import <Masonry.h>
#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width

@interface MSDebugFileModel : NSObject

@property (nonatomic, copy) NSString *superPath; ///< 上一级路径
@property (nonatomic, copy) NSString *name; ///< 文件(夹)名
// 未知、图片、音频、视频、压缩包、txt、pdf、doc、xls、ppt、xml、sql、文件夹
@property (nonatomic, copy) NSString *type; ///< 文件类型
@property (nonatomic, copy) NSString *sizeStr; ///< 文件(夹)大小
@property (nonatomic, assign) unsigned long long size; ///< 文件(夹)大小
@property (nonatomic, assign) CGFloat width; ///< 文件(夹)名宽度
@property (nonatomic, strong) NSMutableArray <MSDebugFileModel *>*files; ///< 下一级数据

@end

@implementation MSDebugFileModel

- (void)setSize:(unsigned long long)size {
    _size = size;
    NSInteger KB = 1024;
    NSInteger MB = KB*KB;
    NSInteger GB = MB*KB;
    if (size < KB) {
        _sizeStr = [NSString stringWithFormat:@"%lld B", size];
    } else if (size < MB) {
        _sizeStr = [NSString stringWithFormat:@"%.1f KB",((CGFloat)size)/KB];
    } else if (size < GB) {
        _sizeStr = [NSString stringWithFormat:@"%.1f MB",((CGFloat)size)/MB];
    } else {
        _sizeStr = [NSString stringWithFormat:@"%.1f GB",((CGFloat)size)/GB];
    }
}

@end

@interface MSDebugFilePreView : UIView

@property (nonatomic, strong, readonly) UITextView *text; ///< txt和plist预览
@property (nonatomic, strong, readonly) UIImageView *image; ///< 图片预览
@property (nonatomic, strong, readonly) WKWebView *web; ///< 文档预览

@end

@interface MSDebugFilePreView () {
    UITextView *_text;
    UIImageView *_image;
    WKWebView *_web;
}

@end

@implementation MSDebugFilePreView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.hidden = YES;
        self.clipsToBounds = YES;
    }
    return self;
}

- (UITextView *)text {
    if (!_text) {
        _text = [UITextView new];
        _text.backgroundColor = [UIColor whiteColor];
        _text.editable = NO;
        _text.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
        [self addSubview:_text];
    }
    [self bringSubviewToFront:_text];
    return _text;
}

- (UIImageView *)image {
    if (!_image) {
        _image = [UIImageView new];
        _image.userInteractionEnabled = YES;
        _image.backgroundColor = [UIColor whiteColor];
        _image.contentMode = UIViewContentModeScaleAspectFit;
        _image.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
        [self addSubview:_image];
    }
    [self bringSubviewToFront:_image];
    return _image;
}

- (WKWebView *)web {
    if (!_web) {
        _web = [[WKWebView alloc] init];
        _web.backgroundColor = UIColor.whiteColor;
        _web.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
        [self addSubview:_web];
    }
    [self bringSubviewToFront:_web];
    return _web;
}

@end

@interface MSDebugTableView : UITableView <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) NSMutableArray <MSDebugFileModel *>*dataArray;
@property (nonatomic, copy) void (^clickIndex)(MSDebugTableView *tableView, MSDebugFileModel *model);
@property (nonatomic, copy) NSString *path;
@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation MSDebugTableView

static NSString * cellIdentifier = @"baseCell";

- (instancetype)init {
    self = [super init];
    if (self) {
        self.delegate = self;
        self.dataSource = self;
        self.backgroundColor = [UIColor whiteColor];
        self.tableFooterView = [[UIView alloc] initWithFrame:(CGRectZero)];
        self.separatorColor = [UIColor colorWithWhite:250/255.0 alpha:1];
        self.rowHeight = 40;
        self.layer.borderWidth = 0.3;
        self.layer.borderColor = [UIColor colorWithWhite:170/255.0 alpha:1].CGColor;
    }
    return self;
}

#pragma mark - tableView代理方法

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleValue1) reuseIdentifier:cellIdentifier];
    }
    MSDebugFileModel *model = self.dataArray[indexPath.row];
    UILabel *label = cell.imageView.subviews.firstObject;
    if (!label) {
        label = [UILabel new];
        label.textColor = UIColor.blackColor;
        label.font = [UIFont systemFontOfSize:11 weight:(UIFontWeightMedium)];
        [cell.imageView addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.offset(0);
            make.centerY.offset(3);
        }];
    }

    UIImage *image = [UIImage imageWithContentsOfFile:[self.bundle pathForResource:[NSString stringWithFormat:@"debug_%@@%.0fx", model.type, UIScreen.mainScreen.scale] ofType:@"png"]];
    if (image) {
        cell.imageView.image = image;
        label.hidden = YES;
        label.text = @"";
    } else {
        cell.imageView.image = [UIImage imageWithContentsOfFile:[self.bundle pathForResource:[NSString stringWithFormat:@"debug_空@%.0fx", UIScreen.mainScreen.scale] ofType:@"png"]];
        label.text = model.type;
        label.hidden = NO;
    }
    cell.textLabel.text = model.name;
    cell.textLabel.textColor = [UIColor colorWithWhite:51/255.0 alpha:1];
    cell.textLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.text = model.sizeStr;
    cell.detailTextLabel.textColor = [UIColor colorWithWhite:102/255.0 alpha:1];
    cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    return cell;
}
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.clickIndex) {
        self.clickIndex(self, self.dataArray[indexPath.row]);
    }
}

@end

@interface MSDebugSandboxViewController ()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *backView;
@property (nonatomic, strong) NSDictionary *typeDict;
@property (nonatomic, strong) NSMutableArray <MSDebugFileModel *>*dataArray;
@property (nonatomic, assign) NSInteger max; ///< 最右侧的tableView下标
@property (nonatomic, strong) MSDebugFilePreView *filePreView; ///< 文件预览
@property (nonatomic, strong) NSBundle *bundle;

@end

@implementation MSDebugSandboxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.scrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    CGFloat SCREEN_HEIGHT = [UIScreen mainScreen].bounds.size.height;
    self.scrollView.contentSize = CGSizeMake(SCREEN_WIDTH, SCREEN_HEIGHT*1.5);
    self.backView.frame = CGRectMake(0, 0, SCREEN_HEIGHT*1.5, SCREEN_WIDTH);
    self.backView.transform = CGAffineTransformMakeRotation(M_PI_2);
    self.backView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT*1.5);
    self.filePreView = [[MSDebugFilePreView alloc] init];
    [self.backView addSubview:self.filePreView];
    self.filePreView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH);
    _dataArray = [NSMutableArray array];
    _typeDict = @{@"txt":@"txt",
                  @"pdf":@"pdf",
                  @"plist":@"xml",
                  @"doc":@"doc",@"docx":@"doc",
                  @"xls":@"xls",@"xlsx":@"xls",
                  @"ppt":@"ppt",@"pptx":@"ppt",
                  @"db":@"sql",@"sqlite":@"sql",
                  @"zip":@"压缩包",@"rar":@"压缩包",
                  @"mp3":@"音频",@"amr":@"音频",@"aac":@"音频",@"wav":@"音频",
                  @"jpg":@"图片",@"png":@"图片",@"jpeg":@"图片",@"gif":@"图片",@"bmp":@"图片",@"tif":@"图片",@"tiff":@"图片",
                  @"mp4":@"视频",@"avi":@"视频",@"mov":@"视频",@"wmv":@"视频",@"3gp":@"视频",@"mkv":@"视频",@"ts":@"视频",@"flv":@"视频",@"f4v":@"视频",@"rmvb":@"视频"};
    [self getDataWithPath:NSHomeDirectory() array:_dataArray];
    
    UIScreenEdgePanGestureRecognizer *edgePan = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self.navigationController.interactivePopGestureRecognizer.delegate action:NSSelectorFromString(@"handleNavigationTransition:")];
    edgePan.edges = UIRectEdgeLeft;
    [self.view addGestureRecognizer:edgePan];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (![self tableViewWithIndex:0].dataArray.count) {
        CGFloat width = [[_dataArray valueForKeyPath:@"@max.width"] floatValue]+130;
        [self tableViewWithIndex:0].dataArray = _dataArray;
        [[self tableViewWithIndex:0] mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.offset(width);
        }];
        CGRect frame = self.filePreView.frame;
        frame.origin.x = width;
        self.filePreView.frame = frame;
        [self.backView layoutIfNeeded];
        frame = self.backView.frame;
        frame.size.height = width+SCREEN_WIDTH;
        self.backView.frame = frame;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, width+SCREEN_WIDTH);
    }
}

- (void)getDataWithPath:(NSString *)superPath array:(NSMutableArray *)array {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *dirArray = [fileManager contentsOfDirectoryAtPath:superPath error:nil];
    for (NSString *subPath in dirArray) {
        NSString *path = [superPath stringByAppendingPathComponent:subPath];
        BOOL directory = NO;
        [fileManager fileExistsAtPath:path isDirectory:&directory];
        MSDebugFileModel *model = [MSDebugFileModel new];
        model.width = [subPath boundingRectWithSize:(CGSizeMake(MAXFLOAT, 40)) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        model.name = subPath;
        model.superPath = superPath;
        if (directory) {
            model.type = @"文件夹";
            model.files = [NSMutableArray array];
            [self getDataWithPath:path array:model.files];
            model.size = [[model.files valueForKeyPath:@"@sum.size"] longLongValue];
        } else {
            model.type = @"  ？";
            NSDictionary *dict = [fileManager attributesOfItemAtPath:path error:nil];
            model.size = [dict[NSFileSize] longLongValue];
            if ([subPath containsString:@"."]) {
                NSString *type = [subPath componentsSeparatedByString:@"."].lastObject.lowercaseString;
                if ([_typeDict.allKeys containsObject:type]) {
                    model.type = _typeDict[type];
                }
            }
        }
        [array addObject:model];
    }
}

- (void)selectRowWithTableView:(MSDebugTableView *)tableView model:(MSDebugFileModel *)model {
    NSInteger index = tableView.tag - 2468;
    CGFloat maxX = CGRectGetMaxX(tableView.frame);
    if ([model.type isEqualToString:@"文件夹"]) {
        CGFloat width = [[model.files valueForKeyPath:@"@max.width"] floatValue]+130;
        [self tableViewWithIndex:index + 1].dataArray = model.files;
        [[self tableViewWithIndex:index + 1] reloadData];
        [[self tableViewWithIndex:index + 1] mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.offset(width);
        }];
        CGRect frame = self.filePreView.frame;
        frame.origin.x = maxX+width;
        self.filePreView.frame = frame;
        [self.backView layoutIfNeeded];
        frame = self.backView.frame;
        frame.size.height = maxX+width+SCREEN_WIDTH;
        self.backView.frame = frame;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, maxX+width+SCREEN_WIDTH);
        self.filePreView.hidden = YES;
    } else {
        CGRect frame = self.filePreView.frame;
        frame.origin.x = maxX;
        self.filePreView.frame = frame;
        [self.backView layoutIfNeeded];
        frame = self.backView.frame;
        frame.size.height = maxX+SCREEN_WIDTH;
        self.backView.frame = frame;
        self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, maxX+SCREEN_WIDTH);
        NSString *path = [model.superPath stringByAppendingPathComponent:model.name];
        self.filePreView.hidden = NO;
        if ([model.type isEqualToString:@"图片"]) {
            self.filePreView.image.image = [UIImage imageWithContentsOfFile:path];
        } else if ([model.type isEqualToString:@"xml"]) {
            self.filePreView.text.text = [[NSDictionary dictionaryWithContentsOfFile:path] descriptionWithLocale:nil];
        } else if ([model.type isEqualToString:@"txt"]) {
            self.filePreView.text.text = [NSString stringWithContentsOfFile:path encoding:(NSUTF8StringEncoding) error:nil];
        } else if ([model.type isEqualToString:@"doc"]||
                   [model.type isEqualToString:@"xls"]||
                   [model.type isEqualToString:@"ppt"]||
                   [model.type isEqualToString:@"pdf"]) {
            [self.filePreView.web loadRequest:[NSURLRequest requestWithURL:[NSURL fileURLWithPath:path]]];
        } else {
            self.filePreView.hidden = YES;
            if ([model.type isEqualToString:@"视频"]||[model.type isEqualToString:@"音频"]) {
                AVPlayerViewController *avPlayer = [[AVPlayerViewController alloc] init];
                avPlayer.player = [[AVPlayer alloc] initWithURL:[NSURL fileURLWithPath:path]];
                avPlayer.videoGravity = AVLayerVideoGravityResizeAspect;
                [avPlayer.player play];
                [self presentViewController:avPlayer animated:YES completion:nil];
            }
        }
    }
    NSInteger hidden = index+[model.type isEqualToString:@"文件夹"];
    for (int i = 0; i <= _max; i++) {
        [self tableViewWithIndex:i].hidden = i > hidden;
    }
}

#pragma mark - 懒加载

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.backgroundColor = UIColor.whiteColor;
        _scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        _scrollView.alwaysBounceVertical = YES;
        _scrollView.alwaysBounceHorizontal = NO;
        _scrollView.delaysContentTouches = NO;
        _scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, SCREEN_WIDTH - 8);
        [self.view addSubview:_scrollView];
    }
    return _scrollView;
}

- (UIView *)backView {
    if (!_backView) {
        _backView = [UIView new];
        _backView.backgroundColor = UIColor.whiteColor;
        [self.scrollView addSubview:_backView];
    }
    return _backView;
}

- (MSDebugTableView *)tableViewWithIndex:(NSInteger)index {
    MSDebugTableView *tableView = [self.backView viewWithTag:2468+index];
    if (!tableView) {
        tableView = [[MSDebugTableView alloc] init];
        tableView.tag = 2468+index;
        tableView.bundle = self.bundle;
        [self.backView addSubview:tableView];
        [tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            index ? make.left.equalTo([self tableViewWithIndex:index - 1].mas_right) : make.left.offset(0);
            make.top.offset(0);
            make.width.height.offset(SCREEN_WIDTH);
        }];
        _max = index;
        __weak typeof(self)weakSelf = self;
        [tableView setClickIndex:^(MSDebugTableView *tableView, MSDebugFileModel *model) {
            [weakSelf selectRowWithTableView:tableView model:model];
        }];
    }
    return tableView;
}

- (NSBundle *)bundle {
    if (!_bundle) {
        _bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"MSDebug" ofType:@"bundle"]];
    }
    return _bundle;
}

@end

#endif
