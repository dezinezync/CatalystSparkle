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
    
//    for (UIWindow *window in [UIApplication.sharedApplication windows]) {
//        if (window.rootViewController && ![NSStringFromClass(window.class) hasPrefix:@"UIText"]) {
//            window.rootViewController.view.backgroundColor = self.isDark ? self.cellColor : self.borderColor;
//            window.tintColor = self.tintColor;
//        }
//
//    };

#endif
    
    UINavigationBar *navBar = [UINavigationBar appearance];
    
    [navBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
    [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
    
//    textField.keyboardAppearance = textView.keyboardAppearance;z
    
    Class splitVCClass = NSClassFromString(@"SplitVC");
    Class navClass = NSClassFromString(@"YTNavigationController");
    Class settingsClass = NSClassFromString(@"SettingsVC");
    
    UITableView *tableView = [UITableView appearanceWhenContainedInInstancesOfClasses:@[splitVCClass, navClass, settingsClass]];
    tableView.backgroundColor = self.tableColor;
    
    UITableViewCell *cell = [UITableViewCell appearanceWhenContainedInInstancesOfClasses:@[splitVCClass, navClass, settingsClass]];
    cell.backgroundColor = self.cellColor;
    
}

@end
