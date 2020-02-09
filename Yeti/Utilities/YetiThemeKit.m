//
//  YetiThemeKit.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiThemeKit.h"
#import "UIColor+Hex.h"
#import "YetiConstants.h"
#import <DZKit/NSString+Extras.h>

YetiThemeKit * YTThemeKit;

NSArray <UIColor *> * _colours;
NSArray <NSString *> * _themeNames;

@interface YetiThemeKit ()

@end

@implementation YetiThemeKit

+ (Class)themeClass {
    return YetiTheme.class;
}

- (BOOL)autoReloadWindow {
    return YES;
}

+ (NSArray <NSString *> *)themeNames {
    
    if (_themeNames == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSArray *themes = nil;
            
            themes = @[@"light", @"reader"];
            
            if (canSupportOLED()) {
                // black should always be last
                themes = [themes arrayByAddingObject:@"black"];
            }
            
            _themeNames = themes.copy;
            themes = nil;
        });
    }
    
    return _themeNames;
    
}

+ (void)loadThemeKit {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
           
            YTThemeKit = [YetiThemeKit new];
            NSArray <UIColor *> *colours = [YetiThemeKit colours];
            
            [[YetiThemeKit themeNames] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
               
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSString *defaultsKey = [NSString stringWithFormat:@"theme-%@-color", obj];
                
                NSURL *path = [[NSBundle bundleForClass:self.class] URLForResource:obj withExtension:@"json"];
                
                __unused YetiTheme *theme = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
                NSInteger tintIndex = [defaults integerForKey:defaultsKey] ?: NSNotFound;
                
                if (tintIndex != NSNotFound) {
                    theme.tintColor = colours[tintIndex];
                }
                
            }];
            
        });
        
    });
    
}

+ (NSArray <UIColor *> *)colours {
    if (!_colours) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _colours = @[
                         [UIColor colorFromHexString:@"007AFF"],
                         [UIColor colorFromHexString:@"ED4A5A"],
                         [UIColor colorFromHexString:@"DD6F2A"],
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
