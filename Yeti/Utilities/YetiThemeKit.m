//
//  YetiThemeKit.m
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiThemeKit.h"

YetiThemeKit * YTThemeKit;

@interface YetiThemeKit ()

@end

@implementation YetiThemeKit

+ (Class)themeClass {
    return YetiTheme.class;
}

+ (void)loadThemeKit {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        YTThemeKit = [YetiThemeKit new];
        
        NSURL *path = [[NSBundle mainBundle] URLForResource:@"light" withExtension:@"json"];
        
        __unused YetiTheme *light = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
        
        path = [[NSBundle mainBundle] URLForResource:@"dark" withExtension:@"json"];
        
        YetiTheme *dark = (YetiTheme *)[YTThemeKit loadColorsFromFile:path];
        dark.dark = YES;
    });
    
}

@end
