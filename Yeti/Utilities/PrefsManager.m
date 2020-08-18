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

PrefsManager * SharedPrefs = nil;

@interface PrefsManager ()

@property (nonatomic, weak, readwrite) NSUserDefaults *defaults;

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
        
        Paragraph.tk_prefsManager = SharedPrefs;
        Content.tk_prefsManager = SharedPrefs;
        
    });
    
    return SharedPrefs;
}

- (void)loadDefaults {
    
    self.theme = [self.defaults stringForKey:kDefaultsTheme] ?: LightTheme;
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

#pragma mark - Notifications

- (void)setupNotifications {
    
#if TARGET_OS_MACCATALYST
    
    NSUserDefaults *defaults = self.defaults;
    
    [defaults addObserver:self forKeyPath:propSel(fontSize) options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:kDefaultsArticleFont options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:kFontSize options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:propSel(lineSpacing) options:NSKeyValueObservingOptionNew context:NULL];
    [defaults addObserver:self forKeyPath:propSel(paraTitleFont) options:NSKeyValueObservingOptionNew context:NULL];
    
#endif
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if (object == self.defaults) {
        
        if ([keyPath isEqualToString:kLineSpacing]
            || [keyPath isEqualToString:propSel(fontSize)]
            || [keyPath isEqualToString:kParagraphTitleFont]
            || [keyPath isEqualToString:kDefaultsArticleFont]
            || [keyPath isEqualToString:propSel(lineSpacing)]
            || [keyPath isEqualToString:propSel(paraTitleFont)]) {
            
            if ([keyPath isEqualToString:propSel(fontSize)]) {
                
                id value = [change valueForKey:NSKeyValueChangeNewKey];
                
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
                
                [self setValue:[change valueForKey:NSKeyValueChangeNewKey] forKey:propSel(lineSpacing)];
                
            }
            else if ([keyPath isEqualToString:propSel(paraTitleFont)]) {
                
                [self setValue:[change valueForKey:NSKeyValueChangeNewKey] forKey:propSel(paraTitleFont)];
                
            }
            
            [self loadDefaults];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [NSNotificationCenter.defaultCenter postNotificationName:UserUpdatedPreferredFontMetrics object:nil];
            });
            
            return;
            
        }
        
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    
}

@end
