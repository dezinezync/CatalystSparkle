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
    };

#endif
    
    UINavigationBar *navBar = [UINavigationBar appearance];
    UITextView *textView = [UITextView appearance];
    UITextField *textField = [UITextField appearance];
    
    if (self.isDark) {
        [navBar setBarStyle:UIBarStyleBlack];
        navBar.translucent = ![self.name isEqualToString:@"black"];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceDark;
    }
    else {
        [navBar setBarStyle:UIBarStyleDefault];
        
//        textView.keyboardAppearance = UIKeyboardAppearanceLight;
    }
    
    textField.keyboardAppearance = textView.keyboardAppearance;
    
    UITableView *tableView = [UITableView appearance];
    tableView.backgroundColor = self.tableColor;
    
    UITableViewCell *cell = [UITableViewCell appearance];
    cell.backgroundColor = self.cellColor;
    
}

@end
