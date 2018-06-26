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

#import "YTUserID.h"
#import "IntroVC.h"

#import "FeedsManager.h"

NSString *const kHasShownOnboarding = @"com.yeti.onboarding.main";

@interface SplitVC ()

@end

@implementation SplitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [YetiThemeKit loadThemeKit];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(userNotFound) name:YTUserNotFound object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didUpdateTheme) name:ThemeDidUpdate object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    UICKeyChainStore *keychain = MyFeedsManager.keychain;
    
    NSString *hasShownIntro = [keychain stringForKey:kHasShownOnboarding];
    
    if (!hasShownIntro || [hasShownIntro boolValue] == NO) {
        [NSNotificationCenter.defaultCenter postNotificationName:YTUserNotFound object:nil];
        [MyFeedsManager.keychain setString:[@(YES) stringValue] forKey:kHasShownOnboarding];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    
    NSString *theme = [NSUserDefaults.standardUserDefaults valueForKey:kDefaultsTheme];
    
    return [theme isEqualToString:LightTheme] ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    
}

#pragma mark -

- (void)userNotFound {
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
    IntroVC *vc = [[IntroVC alloc] initWithNibName:NSStringFromClass(IntroVC.class) bundle:nil];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self presentViewController:nav animated:NO completion:nil];
}

- (void)didUpdateTheme {
    YetiTheme *theme = (YetiTheme *)[YTThemeKit theme];
    
    self.view.backgroundColor = theme.backgroundColor;
}

@end
