//
//  YTNavigationController.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YTNavigationController.h"

@interface YTNavigationController ()

@end

@implementation YTNavigationController

- (BOOL)canBecomeFirstResponder {
    if (self.viewControllers.count) {
        return self.topViewController.canBecomeFirstResponder;
    }
    
    return NO;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.canBecomeFirstResponder) {
        [self becomeFirstResponder];
    }
}

- (NSArray <UIKeyCommand *> *)keyCommands {
    if (self.viewControllers.count) {
        return self.topViewController.keyCommands;
    }
    
    return nil;
}

@end
