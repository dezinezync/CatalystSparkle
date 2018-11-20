//
//  YTNavigationController.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/06/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YTNavigationController.h"
#import "YetiThemeKit.h"

@interface YTNavigationController ()

@end

@implementation YTNavigationController

- (BOOL)canBecomeFirstResponder {
    if (self.viewControllers.count) {
        return self.topViewController.canBecomeFirstResponder;
    }
    
    return NO;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return [[YTThemeKit theme] isDark] ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
}

- (UIViewController *)childViewControllerForStatusBarStyle {
    if (self.presentedViewController) {
        return self.presentedViewController;
    }
    
    if (!self.viewControllers.count) {
        return nil;
    }
    
    return [[self viewControllers] firstObject];
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return [self childViewControllerForStatusBarStyle];
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

#pragma mark -

+ (UIViewController *)viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    return [[[self class] alloc] init];
}

@end
