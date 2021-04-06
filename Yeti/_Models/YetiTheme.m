//
//  YetiTheme.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiTheme.h"

#if TARGET_OS_MACCATALYST
#import "AppDelegate+Catalyst.h"
#endif

#import "PrefsManager.h"

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
//
#if TARGET_OS_MACCATALYST
    [self ct_updateSemanticAppKitColors];
#endif
    
    // @TODO
    

//    [super updateAppearances];

#ifndef SHARE_EXTENSION

    for (UIWindow *window in [UIApplication.sharedApplication windows]) {
        if (window.rootViewController && ![NSStringFromClass(window.class) hasPrefix:@"UIText"]) {
//            window.rootViewController.view.backgroundColor = self.backgroundColor;
            window.tintColor = SharedPrefs.tintColor;
        }

    };

#endif

//    UINavigationBar *navBar = [UINavigationBar appearance];
//
//    [navBar setLargeTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
//    [navBar setTitleTextAttributes:@{NSForegroundColorAttributeName: self.titleColor}];
    
}

#if TARGET_OS_MACCATALYST

- (void)ct_updateSemanticAppKitColors {
    
    self.backgroundColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
            
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            return [UIColor colorWithRed: 0.15 green: 0.15 blue: 0.17 alpha: 1.00];
        }
        
        return [UIColor colorWithRed: 0.91 green: 0.91 blue: 0.91 alpha: 1.00];
        
    }];
    
    self.borderColor = [UIColor colorWithDynamicProvider:^UIColor * _Nonnull(UITraitCollection * _Nonnull traitCollection) {
       
        if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            
            return [UIColor colorWithWhite:1.f alpha:0.12f];
            
        }
        
        return [UIColor colorWithWhite:0.f alpha:0.12f];
        
    }];
    
    self.cellColor = self.backgroundColor;
    self.tableColor = self.cellColor;
    
}

#pragma mark -

- (void)dealloc {
    
    if (_observingHighlightColor == YES) {
    
        [NSUserDefaults.standardUserDefaults removeObserver:self forKeyPath:@"AppleHighlightColor" context:DefaultsAppleHighlightColorContext];
        
    }
    
}

#endif

@end
