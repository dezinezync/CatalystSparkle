//
//  YetiTheme.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiTheme.h"

@implementation YetiTheme

- (void)updateAppearances {
    
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(updateAppearances) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [super updateAppearances];
    
#ifndef SHARE_EXTENSION
    
    for (UIWindow *window in [UIApplication.sharedApplication windows]) {
        window.tintColor = self.tintColor;
        
        if (window.rootViewController) {
            window.rootViewController.view.backgroundColor = self.isDark ? self.cellColor : self.borderColor;
        }
        
    };

#endif
    
    UINavigationBar *navBar = [UINavigationBar appearance];
//    UITextView *textView = [UITextView appearance];
//    UITextField *textField = [UITextField appearance];
    
    // setting this to NO causes jumpy navigation bars
    // update UIViewController to set viewController.extendedLayoutIncludesOpaqueBars=YES;
    navBar.translucent = ![self.name isEqualToString:@"black"];
    
    if (self.isDark) {
        [navBar setBarStyle:UIBarStyleBlack];
        [navBar setBarTintColor:self.cellColor];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    else {
        [navBar setBarStyle:UIBarStyleDefault];
        [navBar setBarTintColor:UIColor.whiteColor];
//        textView.keyboardAppearance = UIKeyboardAppearanceLight;
    }
    
//    textField.keyboardAppearance = textView.keyboardAppearance;
    
    Class splitVCClass = NSClassFromString(@"SplitVC");
    Class navClass = NSClassFromString(@"YTNavigationController");
    Class settingsClass = NSClassFromString(@"SettingsVC");
    
    UITableView *tableView = [UITableView appearanceWhenContainedInInstancesOfClasses:@[splitVCClass, navClass, settingsClass]];
    tableView.backgroundColor = self.tableColor;
    
    UIRefreshControl *refresh = [UIRefreshControl appearance];
    refresh.tintColor = self.isDark ? [UIColor lightGrayColor] : [UIColor darkGrayColor];
    
    UITableViewCell *cell = [UITableViewCell appearance];
    cell.backgroundColor = self.cellColor;
    
    UIScrollView *scrollView = [UIScrollView appearance];
    scrollView.indicatorStyle = self.isDark ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
}

@end
