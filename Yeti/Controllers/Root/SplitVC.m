//
//  SplitVC.m
//  Yeti
//
//  Created by Nikhil Nigade on 01/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "SplitVC.h"
#import "YetiConstants.h"

#import "YetiThemeKit.h"
#import <DZKit/NSArray+RZArrayCandy.h>

@interface SplitVC ()

@end

@implementation SplitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YetiThemeKit loadThemeKit];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    NSString *theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
    
    return [theme isEqualToString:LightTheme] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    
}

@end
