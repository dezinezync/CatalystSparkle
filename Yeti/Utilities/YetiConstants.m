//
//  YetiConstants.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiConstants.h"

#import <UIKit/UIKit.h>
#import <sys/utsname.h>

FMNotification _Nonnull const FeedDidUpReadCount = @"com.yeti.note.feedDidUpdateReadCount";
FMNotification _Nonnull const FeedsDidUpdate = @"com.yeti.note.feedsDidUpdate";
FMNotification _Nonnull const UserDidUpdate = @"com.yeti.note.userDidUpdate";
FMNotification _Nonnull const BookmarksDidUpdate = @"com.yeti.note.bookmarksDidUpdate";
FMNotification _Nonnull const SubscribedToFeed = @"com.yeti.note.subscribedToFeed";

NSString * const kResetAccountSettingsPref = @"reset_account_preference";
NSString * const kHasShownOnboarding = @"com.yeti.onboarding.main";
NSString * const kIsSubscribingToPushNotifications = @"com.yeti.internal.isSubscribingToPushNotifications";

#pragma mark - NSUserDefaults Keys

NSString * const kDefaultsBackgroundRefresh = @"backgroundRefresh";
NSString * const kDefaultsNotifications = @"notifications";
NSString * const kDefaultsImageLoading = @"imageLoading";
NSString * const kDefaultsImageBandwidth = @"imageBandwidth";

NSString * const kShowArticleCoverImages = @"showArticleCoverImages";

#pragma mark - Image Loading

ImageLoadingOption const ImageLoadingLowRes = @"Low Res";
ImageLoadingOption const ImageLoadingMediumRes = @"Medium Res";
ImageLoadingOption const ImageLoadingHighRes = @"High Res";

ImageLoadingOption const ImageLoadingNever = @"Never load images";
ImageLoadingOption const ImageLoadingOnlyWireless = @"Only load on Wi-Fi";
ImageLoadingOption const ImageLoadingAlways = @"Always load images";

#pragma mark - External Apps

ExternalAppsScheme const ExternalTwitterAppScheme = @"externalapp.twitter";
ExternalAppsScheme const ExternalRedditAppScheme = @"externalapp.reddit";
ExternalAppsScheme const ExternalBrowserAppScheme = @"externalapp.browser";

#pragma mark - Theme
NSString * const kDefaultsTheme = @"theme";

YetiThemeType const LightTheme = @"light";
YetiThemeType const DarkTheme = @"dark";
YetiThemeType const ReaderTheme = @"reader";
YetiThemeType const BlackTheme = @"black";

NSNotificationName kWillUpdateTheme = @"com.yeti.note.willUpdateTheme";
NSNotificationName kDidUpdateTheme = @"com.yeti.note.didUpdateTheme";

#pragma mark - Article Layout

NSString * const kDefaultsArticleFont = @"articleFont";



ArticleLayoutFont const ALPSerif = @"articlelayout.georgia";
ArticleLayoutFont const ALPSystem = @"articlelayout.system";
ArticleLayoutFont const ALPHelvetica = @"articlelayout.helveticaNeue";
ArticleLayoutFont const ALPMerriweather = @"articlelayout.merriweather";
ArticleLayoutFont const ALPPlexSerif = @"articlelayout.IBMPlexSerif";
ArticleLayoutFont const ALPPlexSans = @"articlelayout.IBMPlexSans";
ArticleLayoutFont const ALPSpectral = @"articlelayout.Spectral";
ArticleLayoutFont const ALPOpenDyslexic = @"articlelayout.OpenDyslexic";

#pragma mark - Subscription

NSString *const kSubscriptionType = @"subscriptionType";

YetiSubscriptionType const YTSubscriptionMonthly = @"com.dezinezync.elytra.pro.1m";
YetiSubscriptionType const YTSubscriptionYearly = @"com.dezinezync.elytra.pro.12m";

// Use this for Production
#if TESTFLIGHT == 0
NSString * const YTSubscriptionPurchased = @"com.dezinezync.elytra.pro.subscribed";
#else
NSString * const YTSubscriptionPurchased = @"com.dezinezync.elytra.pro.betaSubscribed";
#endif
NSString * const YTSubscriptionHasAddedFirstFeed = @"com.dezinezync.elytra.pro.hasAddedFirstFeed";

NSNotificationName YTSubscriptionHasExpiredOrIsInvalid = @"com.dezinezync.elytra.pro.expiredOrInvalid";

NSNotificationName YTUserPurchasedSubscription = @"com.dezinezync.elytra.pro.purchased";

/*
 * When updating the minor version of the app
 * 1. Copy the value of LaunchCount into LaunchCountOldKey
 * 2. Update the value of the LaunchCount key
 */
NSString * const YTLaunchCountOldKey = @"";
NSString * const YTLaunchCount = @"com.dezinezync.elytra.launchCount-1-6-2";
NSString * const YTRequestedReview = @"com.dezinezync.elytra.requestedReview";

NSString * const YTSubscriptionNotification = @"com.dezinezync.elytra.subscription";

NSString * const kUseExtendedFeedLayout = @"com.dezinezync.elytra.extendedFeedLayout";

NSString * const kShowUnreadCounts = @"com.dezinezync.elytra.showUnreadCounts";
NSNotificationName const ShowUnreadCountsPreferenceChanged = @"com.dezinezync.elytra.note.unreadCountPreferenceChanged";

NSString * const kUseImageProxy = @"com.dezinezync.elytra.useImageProxy";

NSString * const kDetailFeedSorting = @"com.dezinezync.elytra.sortingOption";
YetiSortOption const YTSortAllDesc = @"0";    // 0
YetiSortOption const YTSortAllAsc = @"1";     // 1
YetiSortOption const YTSortUnreadDesc = @"2"; // 2
YetiSortOption const YTSortUnreadAsc = @"3";  // 3

NSString * const kShowMarkReadPrompt = @"com.dezinezync.elytra.showMarkReadPrompt";
NSString * const kHideBookmarksTab = @"com.dezinezync.elytra.hideBookmarksTab";
NSNotificationName const ShowBookmarksTabPreferenceChanged = @"com.dezinezync.elytra.note.showBookmarksTab";
NSString * const kOpenUnreadOnLaunch = @"com.dezinezync.elytra.openUnreadOnLaunch";
NSString * const kShowTags = @"com.dezinezync.elytra.showTags";

NSString * const kUseToolbar = @"com.dezinezync.elytra.useToolbar";

NSString * const IAPOneMonth     = @"com.dezinezync.elytra.non.1m";
NSString * const IAPThreeMonth   = @"com.dezinezync.elytra.non.3m";
NSString * const IAPTwelveMonth  = @"com.dezinezync.elytra.non.12m";
NSString * const IAPLifetime     = @"com.dezinezync.elytra.life";

NSString * const kPreviewLines = @"com.dezinezync.elytra.summaryPreviewLines";

#pragma mark -

NSString * modelIdentifier (void) {
    NSString *simulatorModelIdentifier = [NSProcessInfo processInfo].environment[@"SIMULATOR_MODEL_IDENTIFIER"];
    NSLog(@"%@",simulatorModelIdentifier);
    
    if (simulatorModelIdentifier) {
        return simulatorModelIdentifier;
    }
    
    struct utsname sysInfo;
    uname(&sysInfo);
    
    return [NSString stringWithCString:sysInfo.machine encoding:NSUTF8StringEncoding];
}

// https://gist.github.com/adamawolf/3048717
BOOL canSupportOLED (void) {
    NSSet *const OLEDiPhones = [NSSet setWithObjects:@"iPhone10,3", @"iPhone10,6", @"iPhone11,4", @"iPhone11,2", @"iPhone11,6", nil];
    
    NSString *model = modelIdentifier();
    
    return [OLEDiPhones containsObject:model] || [model hasPrefix:@"iPad8,"];
    
}

@implementation SortImageProvider

+ (UIImage *)imageForSortingOption:(YetiSortOption)option tintColor:(UIColor **)returnColor {
    
    UIColor *tintColor = [SortImageProvider tintColorForSortingOption:option];
    
    NSString *imageName = nil;
    
    if (returnColor != NULL) {
        *returnColor = tintColor;
    }
    
    if ([option isEqualToString:YTSortAllDesc]) {
        imageName = @"calendar";
    }
    else if ([option isEqualToString:YTSortAllAsc]) {
        imageName = @"calendar";
    }
    else if ([option isEqualToString:YTSortUnreadDesc]) {
        imageName = @"exclamationmark.octagon";
    }
    else {
        imageName = @"exclamationmark.octagon";
    }
    
    UIImage * image = [[[UIImage systemImageNamed:imageName] imageWithTintColor:tintColor renderingMode:UIImageRenderingModeAlwaysTemplate] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    return image;
    
}

+ (UIColor *)tintColorForSortingOption:(YetiSortOption)option {
    
    UIColor *color = nil;
    
    if ([option isEqualToString:YTSortAllDesc]) {
        color = UIColor.systemRedColor;
    }
    else if ([option isEqualToString:YTSortAllAsc]) {
        color = UIColor.systemGreenColor;
    }
    else if ([option isEqualToString:YTSortUnreadDesc]) {
        color = UIColor.systemIndigoColor;
    }
    else {
        color = UIColor.systemOrangeColor;
    }
    
    return color;
    
}

@end
