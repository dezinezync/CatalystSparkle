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
    
    navBar.translucent = ![self.name isEqualToString:@"black"];
    
    if (self.isDark) {
        [navBar setBarStyle:UIBarStyleBlack];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    else {
        [navBar setBarStyle:UIBarStyleDefault];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceLight;
    }
    
//    textField.keyboardAppearance = textView.keyboardAppearance;
    
    UITableView *tableView = [UITableView appearance];
    tableView.backgroundColor = self.tableColor;
    
    UITableViewCell *cell = [UITableViewCell appearance];
    cell.backgroundColor = self.cellColor;
    
    UIScrollView *scrollView = [UIScrollView appearance];
    scrollView.indicatorStyle = self.isDark ? UIScrollViewIndicatorStyleWhite : UIScrollViewIndicatorStyleDefault;
    
}

@end
