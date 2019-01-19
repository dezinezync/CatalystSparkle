//
//  PrefsManager.m
//  Yeti
//
//  Created by Nikhil Nigade on 10/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import "PrefsManager.h"

PrefsManager * SharedPrefs = nil;

@interface PrefsManager ()

@property (nonatomic, weak) NSUserDefaults *defaults;

@end

@implementation PrefsManager

+ (void)load {
    [[PrefsManager sharedInstance] loadDefaults];
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
    self.theme = [self.defaults stringForKey:kDefaultsTheme] ?: LightTheme;
    self.backgroundRefresh = [self.defaults boolForKey:kDefaultsBackgroundRefresh];
    self.notifications = [self.defaults boolForKey:kDefaultsNotifications];
    self.imageLoading = [self.defaults stringForKey:kDefaultsImageLoading] ?: ImageLoadingAlways;
    self.imageBandwidth = [self.defaults stringForKey:kDefaultsImageBandwidth] ?: ImageLoadingMediumRes;
    self.articleFont = [self.defaults stringForKey:kDefaultsArticleFont] ?: ALPSystem;
    self.subscriptionType = [self.defaults stringForKey:kSubscriptionType];
    self.articleCoverImages = [self.defaults boolForKey:kShowArticleCoverImages];
    self.showUnreadCounts = [self.defaults boolForKey:kShowUnreadCounts];
    self.imageProxy = [self.defaults boolForKey:kUseImageProxy];
    self.sortingOption = [self.defaults stringForKey:kDetailFeedSorting] ?: YTSortAllDesc;
    self.showMarkReadPrompts = [self.defaults boolForKey:kShowMarkReadPrompt];
    self.openUnread = [self.defaults boolForKey:kOpenUnreadOnLaunch];
    self.hideBookmarks = [self.defaults boolForKey:kHideBookmarksTab];
    self.previewLines = [self.defaults integerForKey:kPreviewLines];
    self.showTags = [self.defaults boolForKey:kShowTags];
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
    
    if (value == nil) {
        [self.defaults removeObjectForKey:key];
    }
    else {
        if ([value isKindOfClass:NSNumber.class]) {
            [self.defaults setInteger:[(NSNumber *)value integerValue] forKey:mapping];
        }
        else if ([NSStringFromClass([value class]) containsString:@"Boolean"]) {
            [self.defaults setBool:value forKey:mapping];
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
    
}

@end
