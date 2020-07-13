//
//  MSDebugAuthorityViewController.m
//  MSDebug
//
//  Created by moses on 2020/7/6.
//  Copyright © 2020 moses. All rights reserved.
//

#ifdef DEBUG

#import "MSDebugAuthorityViewController.h"
#import <UserNotifications/UserNotifications.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <CoreTelephony/CTCellularData.h>
#import <CoreLocation/CoreLocation.h>
#import <Contacts/Contacts.h>
#import <Photos/Photos.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <arpa/inet.h>
#import <mach/mach.h>
#import <ifaddrs.h>
#import <Masonry.h>
#import "MSDebugManager.h"

@interface MSDebugAuthorityViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CTCellularData *cellularData;
@property (nonatomic, strong) NSArray <NSArray <NSString *>*>*dataArray;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *>*dataDict;
@property (nonatomic, strong) NSArray <NSMutableArray <NSNumber *>*>*heightArray; ///< 行高
@property (nonatomic, copy) NSArray *authorityArray; ///< 权限列表
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, weak) id accountInfo; ///< 账号信息

@end

@implementation MSDebugAuthorityViewController

static NSString * cellIdentifier = @"debugCell";

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *keyPath = MSDebugManager.sharedInstace.accountInfoKeyPath;
    if ([keyPath containsString:@"."]) {
        NSArray *arr = [keyPath componentsSeparatedByString:@"."];
        for (int i = 1; i < arr.count; i++) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            _accountInfo = i == 1 ? [NSClassFromString(arr[0]) performSelector:NSSelectorFromString(arr[1])] : [_accountInfo performSelector:NSSelectorFromString(arr[i])];
#pragma clang diagnostic pop
        }
    }
    _authorityArray = @[@"未选择",@"权限受限制",@"已拒绝",@"已授权"];
    _dataDict = [NSMutableDictionary dictionary];
    self.title = @"APP基本信息";
    self.view.backgroundColor = UIColor.whiteColor;
    [self.view addSubview:self.tableView];
    [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.offset(0);
    }];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadData) name:UIApplicationDidBecomeActiveNotification object:nil];
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    _dataDict[@"BundleID"] = infoDict[@"CFBundleIdentifier"];
    _dataDict[@"Version"] = infoDict[@"CFBundleShortVersionString"];
    _dataDict[@"Build Version"] = infoDict[@"CFBundleVersion"];
    struct utsname systemInfo;
    uname(&systemInfo);
    _dataDict[@"设备型号"] = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    _dataDict[@"系统版本"] = UIDevice.currentDevice.systemVersion;
}

- (void)reloadData {
    __weak typeof(self) weakSelf = self;
    // 网络权限
    _cellularData.cellularDataRestrictionDidUpdateNotifier = nil;
    _cellularData = nil;
    _cellularData = [[CTCellularData alloc] init];
    _cellularData.cellularDataRestrictionDidUpdateNotifier = ^(CTCellularDataRestrictedState state) {
        if (state == kCTCellularDataRestricted) {
            weakSelf.dataDict[@"网络权限"] = @"已拒绝";
        } else if (state == kCTCellularDataNotRestricted) {
            weakSelf.dataDict[@"网络权限"] = @"已授权";
        } else {
            weakSelf.dataDict[@"网络权限"] = @"未知";
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    };
    // 推送权限
    if (@available(iOS 10.0, *)) {
        [[UNUserNotificationCenter currentNotificationCenter] getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                weakSelf.dataDict[@"推送权限"] = @"已拒绝";
            } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                NSArray * data = @[@"不支持", @"无", @"有"];
                NSMutableArray *a = [NSMutableArray array];
                [a addObject:[data[settings.badgeSetting] stringByAppendingString:@"标记"]];
                [a addObject:[data[settings.alertSetting] stringByAppendingString:@"弹窗"]];
                [a addObject:[data[settings.soundSetting] stringByAppendingString:@"声音"]];
                [a addObject:[data[settings.notificationCenterSetting] stringByAppendingString:@"通知中心"]];
                [a addObject:[data[settings.lockScreenSetting] stringByAppendingString:@"锁屏显示"]];
                weakSelf.dataDict[@"推送权限"] = [a componentsJoinedByString:@","];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
    } else {
        UIUserNotificationType type = UIApplication.sharedApplication.currentUserNotificationSettings.types;
        if (type == UIUserNotificationTypeNone) {
            _dataDict[@"推送权限"] = @"已拒绝";
        } else {
            NSMutableArray *a = [NSMutableArray array];
            [a addObject:(type & UIUserNotificationTypeBadge) ? @"有标记" : @"无标记"];
            [a addObject:(type & UIUserNotificationTypeAlert) ? @"有弹窗" : @"无弹窗"];
            [a addObject:(type & UIUserNotificationTypeSound) ? @"有声音" : @"无声音"];
            _dataDict[@"推送权限"] = [a componentsJoinedByString:@","];
        }
    }
    _dataDict[@"定位权限"] = [self locationAuthority];
    _dataDict[@"相册权限"] = _authorityArray[[PHPhotoLibrary authorizationStatus]];
    _dataDict[@"相机权限"] = _authorityArray[[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]];
    _dataDict[@"麦克风权限"] = _authorityArray[[AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio]];
    _dataDict[@"通讯录权限"] = _authorityArray[[CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts]];
    // 设备信息
    _dataDict[@"存储空间"] = [NSString stringWithFormat:@"余 %@ / 共 %@", [self fileSizeToString:[self getAvailableDiskSize]], [self fileSizeToString:[self getTotalDiskSize]]];
    _dataDict[@"内存空间"] = [NSString stringWithFormat:@"余 %@ / 共 %@", [self fileSizeToString:[self getAvailableMemorySize]], [self fileSizeToString:NSProcessInfo.processInfo.physicalMemory]];
    _dataDict[@"IP地址"] = [self deviceIPAdress];
    _dataDict[@"Wifi名"] = [self getWifiName];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self reloadData];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    _cellularData.cellularDataRestrictionDidUpdateNotifier = nil;
    _cellularData = nil;
}

- (NSString *)locationAuthority {
    NSString *authority = @"未开启";
    if ([CLLocationManager locationServicesEnabled]) {
        CLAuthorizationStatus state = [CLLocationManager authorizationStatus];
        if (state == kCLAuthorizationStatusNotDetermined) {
            authority = @"未选择";
        } else if (state == kCLAuthorizationStatusRestricted) {
            authority = @"权限受限制";
        } else if (state == kCLAuthorizationStatusDenied) {
            authority = @"已拒绝";
        } else if (state == kCLAuthorizationStatusAuthorizedAlways) {
            authority = @"后台定位";
        } else if (state == kCLAuthorizationStatusAuthorizedWhenInUse) {
            authority = @"前台定位";
        }
    }
    return authority;
}

- (NSString *)deviceIPAdress {
    NSString *address = @"获取失败";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    if (getifaddrs(&interfaces) == 0) {// 0 表示获取成功
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}

- (NSString *)getWifiName {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id reachability = [NSClassFromString(@"AFNetworkReachabilityManager") performSelector:NSSelectorFromString(@"sharedManager")];
#pragma clang diagnostic pop
    // 如果项目使用了AFN,则检测是否有网络
    if (reachability) {
        NSInteger status = [[reachability valueForKey:@"networkReachabilityStatus"] integerValue];
        if (status == 0) {
            return @"当前没有网络";
        }
        if (status == 1) {
            return @"当前为蜂窝网";
        }
    }
    NSString *wifiName = @"获取失败";
    CFArrayRef wifiInterfaces = CNCopySupportedInterfaces();
    NSArray *interfaces = (__bridge NSArray *)wifiInterfaces;
    for (NSString *interfaceName in interfaces) {
        CFDictionaryRef dictRef = CNCopyCurrentNetworkInfo((__bridge CFStringRef)(interfaceName));
        if (dictRef) {
            NSDictionary *networkInfo = (__bridge NSDictionary *)dictRef;
            wifiName = [networkInfo objectForKey:(__bridge NSString *)kCNNetworkInfoKeySSID];
            CFRelease(dictRef);
        }
    }
    if (wifiInterfaces) {
        CFRelease(wifiInterfaces);
    }
    return wifiName;
}

- (unsigned long long)getAvailableMemorySize {
    vm_statistics_data_t vmStats;
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return NSNotFound;
    }
    return ((vm_page_size * vmStats.free_count + vm_page_size * vmStats.inactive_count));
}

- (unsigned long long)getTotalDiskSize {
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_blocks);
    }
    return freeSpace;
}

- (unsigned long long)getAvailableDiskSize {
    struct statfs buf;
    unsigned long long freeSpace = -1;
    if (statfs("/var", &buf) >= 0) {
        freeSpace = (unsigned long long)(buf.f_bsize * buf.f_bavail);
    }
    return freeSpace;
}

- (NSString *)fileSizeToString:(unsigned long long)fileSize {
    NSInteger KB = 1024;
    NSInteger MB = KB*KB;
    NSInteger GB = MB*KB;
    if (fileSize > GB) {
        return [NSString stringWithFormat:@"%.2f GB",((CGFloat)fileSize)/GB];
    }
    if (fileSize > MB) {
        return [NSString stringWithFormat:@"%.2f MB",((CGFloat)fileSize)/MB];
    }
    if (fileSize > KB) {
        return [NSString stringWithFormat:@"%.2f KB",((CGFloat)fileSize)/KB];
    }
    return [NSString stringWithFormat:@"%lld B", fileSize];
}

#pragma mark - tableView代理方法

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @[@"账号信息",@"APP信息",@"系统信息",@"系统权限"][section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.dataArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataArray[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self.heightArray[indexPath.section][indexPath.row] floatValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:(UITableViewCellStyleValue1) reuseIdentifier:cellIdentifier];
    }
    NSString *key = self.dataArray[indexPath.section][indexPath.row];
    cell.textLabel.text = key;
    cell.detailTextLabel.numberOfLines = 0;
    cell.detailTextLabel.text = @"";
    if (indexPath.section) {
        if ([_dataDict.allKeys containsObject:key]) {
            cell.detailTextLabel.text = _dataDict[key];
        }
    } else {
        NSString *s = [_accountInfo valueForKeyPath:key];
        if ([s isKindOfClass:[NSString class]]) {
            cell.detailTextLabel.text = s;
        } else if ([s isKindOfClass:[NSNumber class]]) {
            cell.detailTextLabel.text = [(NSNumber *)s stringValue];
        } else if ([s isKindOfClass:[NSArray class]]) {
            cell.detailTextLabel.text = [(NSArray *)s componentsJoinedByString:@","];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height = cell.detailTextLabel.bounds.size.height + 28;
    if (height > 50) {
        self.heightArray[indexPath.section][indexPath.row] = @(height);
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 3) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([cell.detailTextLabel.text isEqualToString:@"未选择"]) {
            if ([cell.textLabel.text isEqualToString:@"定位权限"]) {
                _locationManager = [CLLocationManager new];
                [_locationManager requestAlwaysAuthorization];
                [_locationManager requestWhenInUseAuthorization];
            } else if ([cell.textLabel.text isEqualToString:@"相册权限"]) {
                [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {}];
            } else if ([cell.textLabel.text isEqualToString:@"相机权限"]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {}];
            } else if ([cell.textLabel.text isEqualToString:@"麦克风权限"]) {
                [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {}];
            } else if ([cell.textLabel.text isEqualToString:@"通讯录权限"]) {
                [[CNContactStore new] requestAccessForEntityType:(CNEntityTypeContacts) completionHandler:^(BOOL granted, NSError * _Nullable error) {
                    [self reloadData];
                }];
            }
        } else if ([cell.detailTextLabel.text isEqualToString:@"已拒绝"]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (@available(iOS 10, *)) {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
                } else {
                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                }
            });
        }
    }
}

#pragma mark - 懒加载

- (UITableView *)tableView {
    if (!_tableView) {
        UITableView *tableView = [[UITableView alloc] init];
        tableView.backgroundColor = [UIColor whiteColor];
        tableView.tableFooterView = [[UIView alloc] initWithFrame:(CGRectZero)];
        tableView.sectionHeaderHeight = 40;
        tableView.delegate = self;
        tableView.dataSource = self;
        _tableView = tableView;
    }
    return _tableView;
}

- (NSArray *)dataArray {
    if (!_dataArray) {
        _dataArray = @[MSDebugManager.sharedInstace.accountInfoKeys ?: @[],
                       @[@"BundleID", @"Version", @"Build Version"],
                       @[@"设备型号", @"系统版本", @"存储空间", @"内存空间", @"IP地址", @"Wifi名"],
                       @[@"网络权限", @"定位权限", @"推送权限", @"相册权限", @"相机权限", @"麦克风权限", @"通讯录权限"]];
    }
    return _dataArray;
}

- (NSArray<NSMutableArray<NSNumber *> *> *)heightArray {
    if (!_heightArray) {
        NSMutableArray *heights = [NSMutableArray arrayWithCapacity:4];
        for (NSArray *arr in self.dataArray) {
            NSMutableArray *height = [NSMutableArray arrayWithCapacity:arr.count];
            [heights addObject:height];
            for (int i = 0; i < arr.count; i++) {
                [height addObject:@50];
            }
        }
        _heightArray = [heights copy];
    }
    return _heightArray;
}

@end

#endif
