//
//  YetiTheme.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiTheme.h"

@implementation YetiTheme

- (NSArray <NSString *> *)additionalKeyPaths {
    
    return @[@"cellColor",
             @"unreadBadgeColor",
             @"unreadTextColor",
             @"articlesBarColor",
             @"subbbarColor",
             @"focusColor",
             @"articleBackgroundColor",
             @"opmlViewColor",
             @"menuColor",
             @"menuTextColor",
             @"paragraphColor"];
    
}

- (void)updateAppearances {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateAppearances) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [super updateAppearances];
    
#ifndef SHARE_EXTENSION
    
    for (UIWindow *window in [UIApplication.sharedApplication windows]) {
        if (window.rootViewController && ![NSStringFromClass(window.class) hasPrefix:@"UIText"]) {
            window.rootViewController.view.backgroundColor = self.isDark ? self.cellColor : self.borderColor;
            window.tintColor = self.tintColor;
        }
        
    };

#endif
    
    UINavigationBar *navBar = [UINavigationBar appearance];
    UIToolbar *toolbar = [UIToolbar appearance];
//    UITextView *textView = [UITextView appearance];
//    UITextField *textField = [UITextField appearance];
    
    // setting this to NO causes jumpy navigation bars
    // update UIViewController to set viewController.extendedLayoutIncludesOpaqueBars=YES;
    if (@available(iOS 13, *)) {}
    else {
        navBar.translucent = ![self.name isEqualToString:@"black"];
    }
    
    if (self.isDark) {
        [navBar setBarStyle:UIBarStyleBlack];
        [navBar setBarTintColor:self.cellColor];
        
        [toolbar setBarStyle:UIBarStyleBlack];
        [toolbar setBarTintColor:self.cellColor];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    else {
        [navBar setBarStyle:UIBarStyleDefault];
        [navBar setBarTintColor:self.articleBackgroundColor];
        
        [toolbar setBarStyle:UIBarStyleDefault];
        [toolbar setBarTintColor:self.articleBackgroundColor];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceLight;
    }
    
    [navBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
    [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
    
//    textField.keyboardAppearance = textView.keyboardAppearance;
    
    Class splitVCClass = NSClassFromString(@"SplitVC");
    Class navClass = NSClassFromString(@"YTNavigationController");
    Class settingsClass = NSClassFromString(@"SettingsVC");
    
    UITableView *tableView = [UITableView appearanceWhenContainedInInstancesOfClasses:@[splitVCClass, navClass, settingsClass]];
    tableView.backgroundColor = self.tableColor;
    
    UIRefreshControl *refresh = [UIRefreshControl appearance];
    refresh.tintColor = self.isDark ? [UIColor lightGrayColor] : [UIColor darkGrayColor];
    
    UITableViewCell *cell = [UITableViewCell appearanceWhenContainedInInstancesOfClasses:@[splitVCClass, navClass, settingsClass]];
    cell.backgroundColor = self.cellColor;
    
    UIScrollView *scrollView = [UIScrollView appearance];
    scrollView.indicatorStyle = self.isDark ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
}

@end
