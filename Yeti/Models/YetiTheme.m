//
//  YetiTheme.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiTheme.h"
#import "AppKitGlue.h"

#if TARGET_OS_MACCATALYST
#import "AppDelegate+Catalyst.h"
#endif

static void * DefaultsAppleHighlightColorContext = &DefaultsAppleHighlightColorContext;

@interface YetiTheme () {
    
    BOOL _observingHighlightColor;
    
}

@end

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
    
#if TARGET_OS_MACCATALYST
    [self ct_hookAndUpdateTintColor];
    [self ct_updateSemanticAppKitColors];
#endif
    
    [super updateAppearances];
    
#ifndef SHARE_EXTENSION
    
    for (UIWindow *window in [UIApplication.sharedApplication windows]) {
        if (window.rootViewController && ![NSStringFromClass(window.class) hasPrefix:@"UIText"]) {
            window.rootViewController.view.backgroundColor = self.backgroundColor;
            window.tintColor = self.tintColor;
        }

    };

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

- (void)ct_hookAndUpdateTintColor {
    
#if TARGET_OS_MACCATALYST
    
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    
    [defaults addObserver:self forKeyPath:@"AppleHighlightColor" options:NSKeyValueObservingOptionNew context:DefaultsAppleHighlightColorContext];
    
    _observingHighlightColor = YES;
    
    [self ct_updateTintColor:defaults];
    
#endif
    
}

#if TARGET_OS_MACCATALYST

- (void)ct_updateTintColor:(NSUserDefaults *)defaults {
    
    NSString *systemHighlightColor = [defaults objectForKey:@"AppleHighlightColor"];
    
    if (systemHighlightColor == nil) {
        
        self.tintColor = [UIColor systemBlueColor];
        
        return;
        
    }
    
    NSArray *components = [systemHighlightColor componentsSeparatedByString:@" "];
    NSString *colorName = [components lastObject];
    
    SEL systemColorSelector = NSSelectorFromString([NSString stringWithFormat:@"system%@Color", colorName]);
    
    if ([UIColor respondsToSelector:systemColorSelector] == YES) {
        
        UIColor * systemTintColor = [UIColor performSelector:systemColorSelector];
        
        if (systemTintColor != nil) {
            
            self.tintColor = systemTintColor;
            
        }
        
    }
    else if ([colorName isEqualToString:@"Graphite"]) {
        
        self.tintColor = UIColor.systemGrayColor;
        
    }
    
}

- (void)ct_updateSemanticAppKitColors {
    
    self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed: 0.15 green: 0.15 blue: 0.17 alpha: 1.00];
        }
        
        return [UIColor colorWithRed: 0.91 green: 0.91 blue: 0.91 alpha: 1.00];
        
    }];
    
    self.borderColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
       
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            
            return [UIColor colorWithRed: 0.21 green: 0.22 blue: 0.24 alpha: 1.00];
            
        }
        
        return [UIColor colorWithRed: 0.80 green: 0.80 blue: 0.80 alpha: 1.00];
        
    }];
    
    self.cellColor = self.backgroundColor;
    self.tableColor = self.cellColor;
    
}

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"AppleHighlightColor"] && context == DefaultsAppleHighlightColorContext) {
        
        [self ct_updateTintColor:object];
        
        [self updateAppearances];
        
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
    
}

- (void)dealloc {
    
    if (_observingHighlightColor == YES) {
    
        [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"AppleHighlightColor" context:DefaultsAppleHighlightColorContext];
        
    }
    
}

#endif

@end
