//
//  YetiThemeKit.h
//  Yeti
//
//  Created by Nikhil Nigade on 02/05/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <DZThemeKit/DZThemeKit.h>
#import "YetiTheme.h"

@class YetiThemeKit;

extern YetiThemeKit * _Nonnull YTThemeKit;

@interface YetiThemeKit : ThemeKit

/**
 Initialize DZThemeKit. Makes MyThemeKit available.
 */
+ (void)loadThemeKit;

+ (NSArray <UIColor *> *)colours;

+ (NSArray <NSString *> *)themeNames;

@end
