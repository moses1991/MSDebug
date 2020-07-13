//
//  ViewController.m
//  MSDebugDemo
//
//  Created by moses on 2020/6/30.
//  Copyright © 2020 moses. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSLog(@"我来了😁\n我来了😁\n我来了😁\n我来了😁");
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"我走了😁\n我走了😁\n我走了😁\n我走了😁");
}

@end
