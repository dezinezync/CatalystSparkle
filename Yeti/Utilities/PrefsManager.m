//
//  PrefsManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PrefsManager.h"
#import "YetiConstants.h"

#import "Paragraph.h"
#import "Content.h"

#import "YetiThemeKit.h"
#import "ThemeVC.h"

static void * DefaultsAppleHighlightColorContext = &DefaultsAppleHighlightColorContext;

PrefsManager * SharedPrefs = nil;

@interface PrefsManager ()

@property (nonatomic, weak, readwrite) NSUserDefaults *defaults;

#if TARGET_OS_MACCATALYST
@property (nonatomic, weak) id defaultsController;
#endif

@end

@implementation PrefsManager

+ (void)load {
    
    [[PrefsManager sharedInstance] loadDefaults];
    [[PrefsManager sharedInstance] setupNotifications];
    
}

+ (instancetype)sharedInstance {
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        SharedPrefs = [[PrefsManager alloc] init];
        SharedPrefs.defaults = [NSUserDefaults standardUserDefaults];
        
    });
    
    return SharedPrefs;
}

- (void)loadDefaults {
    
//    self.theme = [self.defaults stringForKey:kDefaultsTheme] ?: LightTheme;
    self.theme = LightTheme;
    
    self.backgroundRefresh = ([self.defaults valueForKey:kDefaultsBackgroundRefresh] ? [[self.defaults valueForKey:kDefaultsBackgroundRefresh] boolValue] : YES);
    self.notifications = [self.defaults boolForKey:kDefaultsNotifications];
    self.imageLoading = [self.defaults stringForKey:kDefaultsImageLoading] ?: ImageLoadingAlways;
    self.imageBandwidth = [self.defaults stringForKey:kDefaultsImageBandwidth] ?: ImageLoadingMediumRes;
    self.articleFont = [self.defaults stringForKey:kDefaultsArticleFont] ?: ALPSystem;
    self.subscriptionType = [self.defaults stringForKey:kSubscriptionType];
    self.articleCoverImages = ([self.defaults valueForKey:kShowArticleCoverImages] ? [[self.defaults valueForKey:kShowArticleCoverImages] boolValue] : YES);
    self.showUnreadCounts = ([self.defaults valueForKey:kShowUnreadCounts] ? [[self.defaults valueForKey:kShowUnreadCounts] boolValue] : YES);
    self.imageProxy = ([self.defaults valueForKey:kUseImageProxy] ? [[self.defaults valueForKey:kUseImageProxy] boolValue] : YES);
    self.sortingOption = [self.defaults stringForKey:kDetailFeedSorting] ?: YTSortAllDesc;
    self.showMarkReadPrompts = ([self.defaults valueForKey:kShowMarkReadPrompt] ? [[self.defaults valueForKey:kShowMarkReadPrompt] boolValue] : YES);
    self.openUnread = ([self.defaults valueForKey:kOpenUnreadOnLaunch] ? [[self.defaults valueForKey:kOpenUnreadOnLaunch] boolValue] : NO);
    self.hideBookmarks = ([self.defaults valueForKey:kHideBookmarksTab] ? [[self.defaults valueForKey:kHideBookmarksTab] boolValue] : NO);
    self.previewLines = [self.defaults integerForKey:kPreviewLines] ?: 0;
    self.showTags = ([self.defaults valueForKey:kShowTags] ? [[self.defaults valueForKey:kShowTags] boolValue] : YES);
    self.useToolbar = ([self.defaults valueForKey:kUseToolbar] ? [[self.defaults valueForKey:kUseToolbar] boolValue] : NO);
    self.hideBars = ([self.defaults valueForKey:kHideBars] ? [[self.defaults valueForKey:kHideBars] boolValue] : NO );
    
    self.useSystemSize = ([self.defaults valueForKey:kUseSystemFontSize] ? [[self.defaults valueForKey:kUseSystemFontSize] boolValue] : YES);
    self.fontSize = ([self.defaults valueForKey:kFontSize] ? [[self.defaults valueForKey:kFontSize] integerValue] : [UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize);
    self.paraTitleFont = [self.defaults valueForKey:kParagraphTitleFont];
    self.lineSpacing = ([self.defaults floatForKey:kLineSpacing] ?: 1.4f);
    
    NSString *defaultsKey = formattedString(@"theme-%@-color", @"default");
    
    self.iOSTintColorIndex = [self.defaults integerForKey:defaultsKey] ?: 0;
    self.tintColor = [YetiThemeKit.colours objectAtIndex:self.iOSTintColorIndex];
    
#if TARGET_OS_MACCATALYST
    self.browserOpenInBackground = [self.defaults boolForKey:MacKeyOpensBrowserInBackground];
    self.browserUsesReaderMode = [self.defaults boolForKey:OpenBrowserInReaderMode];
    self.refreshFeedsInterval = [self.defaults valueForKey:MacKeyRefreshFeeds];
    
    [self ct_updateTintColor:self.defaults];
    [self updateAppearances];
    
#endif
    self.badgeAppIcon = [self.defaults boolForKey:badgeAppIconPreference];
    
    if (self.paraTitleFont == nil) {
        self.paraTitleFont = ALPSystem;
    }
    
    if (self.articleFont == nil) {
        self.articleFont = ALPSystem;
    }
    
}

- (NSString *)mappingForKey:(NSString *)key {
    
    if ([key isEqualToString:propSel(theme)]) {
        return kDefaultsTheme;
    }
    else if ([key isEqualToString:propSel(backgroundRefresh)]) {
        return kDefaultsBackgroundRefresh;
    }
    else if ([key isEqualToString:propSel(notifications)]) {
        return kDefaultsNotifications;
    }
    else if ([key isEqualToString:propSel(imageLoading)]) {
        return kDefaultsImageLoading;
    }
    else if ([key isEqualToString:propSel(imageBandwidth)]) {
        return kDefaultsImageBandwidth;
    }
    else if ([key isEqualToString:propSel(articleFont)]) {
        return kDefaultsArticleFont;
    }
    else if ([key isEqualToString:propSel(subscriptionType)]) {
        return kSubscriptionType;
    }
    else if ([key isEqualToString:propSel(articleCoverImages)]) {
        return kShowArticleCoverImages;
    }
    else if ([key isEqualToString:propSel(showUnreadCounts)]) {
        return kShowUnreadCounts;
    }
    else if ([key isEqualToString:propSel(sortingOption)]) {
        return kDetailFeedSorting;
    }
    else if ([key isEqualToString:propSel(showMarkReadPrompts)]) {
        return kShowMarkReadPrompt;
    }
    else if ([key isEqualToString:propSel(openUnread)]) {
        return kOpenUnreadOnLaunch;
    }
    else if ([key isEqualToString:propSel(hideBookmarks)]) {
        return kHideBookmarksTab;
    }
    else if ([key isEqualToString:propSel(previewLines)]) {
        return kPreviewLines;
    }
    else if ([key isEqualToString:propSel(showTags)]) {
        return kShowTags;
    }
    else if ([key isEqualToString:propSel(imageProxy)]) {
        return kUseImageProxy;
    }
    else if ([key isEqualToString:propSel(useToolbar)]) {
        return kUseToolbar;
    }
    else if ([key isEqualToString:propSel(useSystemSize)]) {
        return kUseSystemFontSize;
    }
    else if ([key isEqualToString:propSel(fontSize)]) {
        return kFontSize;
    }
    else if ([key isEqualToString:propSel(paraTitleFont)]) {
        return kParagraphTitleFont;
    }
    else if ([key isEqualToString:propSel(lineSpacing)]) {
        return kLineSpacing;
    }
    else if ([key isEqualToString:propSel(hideBars)]) {
        return kHideBars;
    }
    else if ([key isEqualToString:propSel(iOSTintColorIndex)]) {
        return formattedString(@"theme-%@-color", @"default");
    }
#if TARGET_OS_MACCATALYST
    else if ([key isEqualToString:propSel(browserOpenInBackground)]) {
        return MacKeyOpensBrowserInBackground;
    }
    else if ([key isEqualToString:propSel(browserUsesReaderMode)]) {
        return OpenBrowserInReaderMode;
    }
    else if ([key isEqualToString:propSel(refreshFeedsInterval)]) {
        return MacKeyRefreshFeeds;
    }
#endif
    else if ([key isEqualToString:propSel(badgeAppIcon)]) {
        return badgeAppIconPreference;
    }
//    else if ([key isEqualToString:propSel(<#string#>)]) {
//        return <#mapping#>;
//    }
    else {
        return nil;
    }
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    
    [super setValue:value forKey:key];
    
    NSString *mapping = [self mappingForKey:key];
    
    if (mapping == nil) {
        return;
    }
    
    if (value == nil || [value isKindOfClass:NSNull.class]) {
        [self.defaults removeObjectForKey:key];
    }
    else {
        if ([value isKindOfClass:NSClassFromString(@"__NSCFBoolean")]) {
            [self.defaults setValue:value forKey:mapping];
        }
        else if ([value isKindOfClass:NSNumber.class]) {
            
            if ([mapping isEqualToString:kLineSpacing]) {
                [self.defaults setFloat:[(NSNumber *)value floatValue] forKey:mapping];
            }
            else {
                [self.defaults setInteger:[(NSNumber *)value integerValue] forKey:mapping];
            }
            
        }
        else if ([NSStringFromClass([value class]) containsString:@"Boolean"]) {
            [self.defaults setBool:[value boolValue] forKey:mapping];
        }
        else {
            [self.defaults setValue:value forKey:mapping];
        }
    }
    
    [self.defaults synchronize];
    
    if ([key isEqualToString:propSel(hideBookmarks)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:ShowBookmarksTabPreferenceChanged object:nil];
        });
    }
    else if ([key isEqualToString:propSel(showUnreadCounts)]) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:ShowUnreadCountsPreferenceChanged object:nil];
        });
        
    }
    else if ([@[propSel(lineSpacing), propSel(fontSize), propSel(useSystemSize), propSel(paraTitleFont), propSel(articleFont), propSel(theme)] indexOfObject:key] != NSNotFound) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSNotificationCenter.defaultCenter postNotificationName:UserUpdatedPreferredFontMetrics object:nil];
        });
        
    }
    
}

#pragma mark - Getter

#if TARGET_OS_MACCATALYST

- (NSTimeInterval)refreshFeedsTimeInterval {
    
    NSString *str = self.refreshFeedsInterval;
    NSTimeInterval value;
    
    if ([str isEqualToString:@"Every 30 minutes"]) {
#ifdef DEBUG
        value = (1 * 60);
#else
        value = (30 * 60);
#endif
    }
    else if ([str isEqualToString:@"Every Hour"]) {
#ifdef DEBUG
        value = (5 * 60);
#else
        value = (60 * 60);
#endif
    }
    else {
        value = -1;
    }

    return value;
    
}

#endif

#pragma mark - Notifications

- (void)setupNotifications {
    
    NSUserDefaults *defaults = self.defaults;
    
#if TARGET_OS_MACCATALYST
    
    [defaults addObserver:self forKeyPath:propSel(fontSize) options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:kDefaultsArticleFont options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:kFontSize options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:propSel(lineSpacing) options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:propSel(paraTitleFont) options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:kShowArticleCoverImages options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:OpenBrowserInReaderMode options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:kDefaultsImageBandwidth options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:MacKeyOpensBrowserInBackground options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:MacKeyRefreshFeeds options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:@"paraTitleFontReadable" options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:@"articleFontReadable" options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:@"MacHideBookmarksTab" options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:@"MacShowUnreadCounters" options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:@"MacSummaryPreviewLines" options:NSKeyValueObservingOptionNew context:NULL];
    
    [defaults addObserver:self forKeyPath:@"AppleHighlightColor" options:NSKeyValueObservingOptionNew context:DefaultsAppleHighlightColorContext];
    
    if (self.defaultsController == nil) {
        Class controller = NSClassFromString(@"NSUserDefaultsController");
        SEL selector = NSSelectorFromString(@"sharedUserDefaultsController");
        id instance = [controller performSelector:selector];
        
        self.defaultsController = instance;
        
        [instance addObserver:self forKeyPath:@"values.com.dezinezync.elytra.showMarkReadPrompt" options:NSKeyValueObservingOptionNew context:NULL];
    }
    
#endif
    
    [defaults addObserver:self forKeyPath:badgeAppIconPreference options:NSKeyValueObservingOptionNew context:NULL];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    id value = [change valueForKey:NSKeyValueChangeNewKey];
    
    if (object == self.defaults) {
        
        if ([keyPath isEqualToString:kShowArticleCoverImages]) {
            
            [self setValue:value forKey:propSel(articleCoverImages)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:ArticleCoverImagesPreferenceUpdated object:nil];
            
        }
        else if ([keyPath isEqualToString:OpenBrowserInReaderMode]) {
            
            [self setValue:value forKey:propSel(browserUsesReaderMode)];
            
        }
#if TARGET_OS_MACCATALYST
        else if ([keyPath isEqualToString:MacKeyOpensBrowserInBackground]) {
            
            [self setValue:value forKey:propSel(browserOpenInBackground)];
            
        }
        else if ([keyPath isEqualToString:MacKeyRefreshFeeds]) {
            
            [self setValue:value forKey:propSel(refreshFeedsInterval)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:MacRefreshFeedsIntervalUpdated object:nil];
            
        }
#endif
        else if ([keyPath isEqualToString:kDefaultsImageBandwidth]) {
            
            [self setValue:value forKey:propSel(imageBandwidth)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:ImageBandWidthPreferenceUpdated object:nil];
            
        }
        else if ([keyPath isEqualToString:@"MacHideBookmarksTab"]) {
            
            [self setValue:value forKey:keypath(hideBookmarks)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:ShowBookmarksTabPreferenceChanged object:nil];
            
        }
        else if ([keyPath isEqualToString:@"MacShowUnreadCounters"]) {
            
            [self setValue:value forKey:keypath(showUnreadCounts)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:ShowUnreadCountsPreferenceChanged object:nil];
            
        }
        else if ([keyPath isEqualToString:@"MacSummaryPreviewLines"]) {
            
            [self setValue:value forKey:keypath(previewLines)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:PreviewLinesPreferenceUpdated object:nil];
            
        }
        else if ([keyPath isEqualToString:badgeAppIconPreference]) {
            
            [self setValue:value forKey:keypath(badgeAppIcon)];
            
            [NSNotificationCenter.defaultCenter postNotificationName:BadgeAppIconPreferenceUpdated object:nil];
            
        }
        else if ([keyPath isEqualToString:kShowMarkReadPrompt]) {
            
            [self setValue:value forKey:keypath(showMarkReadPrompts)];
            
        }
        else if ([keyPath isEqualToString:@"AppleHighlightColor"] && context == DefaultsAppleHighlightColorContext) {
            
            [self ct_updateTintColor:object];
            
            [self updateAppearances];
            
        }
        else if ([keyPath isEqualToString:kLineSpacing]
            || [keyPath isEqualToString:propSel(fontSize)]
            || [keyPath isEqualToString:kParagraphTitleFont]
            || [keyPath isEqualToString:kDefaultsArticleFont]
            || [keyPath isEqualToString:propSel(lineSpacing)]
            || [keyPath isEqualToString:propSel(paraTitleFont)]
            || [keyPath isEqualToString:propSel(articleFont)]
            || [keyPath isEqualToString:@"paraTitleFontReadable"]
            || [keyPath isEqualToString:@"articleFontReadable"]) {
            
            if ([keyPath isEqualToString:propSel(fontSize)]) {
                
                if ([value boolValue] == NO || [value floatValue] == 0.f) {
                    [self setValue:@(YES) forKey:propSel(useSystemSize)];
                }
                else {
                    [self setValue:@(NO) forKey:propSel(useSystemSize)];
                }
                
                CGFloat val = [(NSNumber *)value floatValue];
                
                [self setValue:@(val) forKey:propSel(fontSize)];
                
            }
            else if ([keyPath isEqualToString:propSel(lineSpacing)]) {
                
                [self setValue:value forKey:propSel(lineSpacing)];
                
            }
            
            else if ([keyPath isEqualToString:propSel(paraTitleFont)]) {
                
                NSString *readable = ThemeVC.fontNamesMap[value];
                
                [self setValue:value forKey:propSel(paraTitleFont)];
                
                [NSUserDefaults.standardUserDefaults setObject:readable forKey:@"paraTitleFontReadable"];
                [NSUserDefaults.standardUserDefaults synchronize];
                
            }
            else if ([keyPath isEqualToString:propSel(articleFont)] || [keyPath isEqualToString:kDefaultsArticleFont]) {
                
                NSString *readable = ThemeVC.fontNamesMap[value];
                
                [self setValue:value forKey:propSel(articleFont)];
                
                [NSUserDefaults.standardUserDefaults setObject:readable forKey:@"articleFontReadable"];
                [NSUserDefaults.standardUserDefaults synchronize];
                
            }
            else if ([keyPath isEqualToString:@"paraTitleFontReadable"]) {
                
                NSUInteger readableIndex = [ThemeVC.fontNamesMap.allValues indexOfObject:value];
                NSString *source = ThemeVC.fontNamesMap.allKeys[readableIndex];
                
                [self setValue:source forKey:propSel(paraTitleFont)];
                
            }
            else if ([keyPath isEqualToString:@"articleFontReadable"]) {
                
                NSUInteger readableIndex = [ThemeVC.fontNamesMap.allValues indexOfObject:value];
                NSString *source = ThemeVC.fontNamesMap.allKeys[readableIndex];
                
                [self setValue:source forKey:propSel(articleFont)];
                
            }
            
            [self loadDefaults];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:UserUpdatedPreferredFontMetrics object:nil];
            });
            
        }
        
        return;
        
    }
    else if (object == self.defaultsController) {
        
        value = [self.defaults valueForKey:[keyPath substringFromIndex:7]];
        
        if ([keyPath containsString:kShowMarkReadPrompt]) {
            
            [self setValue:value forKey:keypath(showMarkReadPrompts)];
            
        }
        
        return;
        
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
}

#pragma mark -

- (void)updateAppearances {
    
    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        
        for (UIWindow *window in scene.windows) {
            
            window.tintColor = self.tintColor;
            
        }
        
    }
    
}

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

@end
