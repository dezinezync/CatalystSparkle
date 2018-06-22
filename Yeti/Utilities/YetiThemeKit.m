//
//  YetiThemeKit.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiThemeKit.h"
#import "UIColor+Hex.h"
#import <DZKit/NSString+Extras.h>

YetiThemeKit * YTThemeKit;

NSArray <UIColor *> * _colours;

@interface YetiThemeKit ()

@end

@implementation YetiThemeKit

+ (Class)themeClass {
    return YetiTheme.class;
}

- (BOOL)autoReloadWindow {
    return YES;
}

+ (void)loadThemeKit {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        YTThemeKit = [YetiThemeKit new];
        NSArray <UIColor *> *colours = [YetiThemeKit colours];;
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *defaultsKey = [NSString stringWithFormat:@"theme-%@-color", @"light"];
        
        NSURL *path = [[NSBundle mainBundle] URLForResource:@"light" withExtension:@"json"];
        
        __unused YetiTheme *light = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
        NSInteger tintIndex = [defaults integerForKey:defaultsKey];
        
        if (tintIndex != NSNotFound) {
            light.tintColor = colours[tintIndex];
            tintIndex = NSNotFound;
        }
        
        path = [[NSBundle mainBundle] URLForResource:@"dark" withExtension:@"json"];
        
        YetiTheme *dark = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
        dark.dark = YES;
        
        defaultsKey = [NSString stringWithFormat:@"theme-%@-color", @"dark"];
        tintIndex = [defaults integerForKey:defaultsKey];
        
        if (tintIndex != NSNotFound) {
            dark.tintColor = colours[tintIndex];
            tintIndex = NSNotFound;
        }
        
        path = [[NSBundle mainBundle] URLForResource:@"black" withExtension:@"json"];
        
        YetiTheme *black = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
        black.dark = YES;
        
        defaultsKey = [NSString stringWithFormat:@"theme-%@-color", @"black"];
        tintIndex = [defaults integerForKey:defaultsKey];
        
        if (tintIndex != NSNotFound) {
            black.tintColor = colours[tintIndex];
            tintIndex = NSNotFound;
        }
    });
    
}

+ (NSArray <UIColor *> *)colours {
    if (!_colours) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _colours = @[
                         [UIColor colorFromHexString:@"007AFF"],
                         [UIColor colorFromHexString:@"DF4D4A"],
                         [UIColor colorFromHexString:@"E8883A"],
                         [UIColor colorFromHexString:@"F2BB4B"],
                         [UIColor colorFromHexString:@"78B856"],
                         [UIColor colorFromHexString:@"45A1E8"],
                         [UIColor colorFromHexString:@"E45C9C"],
                         [UIColor colorFromHexString:@"8FA0AB"],
                         [UIColor colorFromHexString:@"6C86F7"]
            ];
        });
    }
    
    return _colours;
}

@end
