//
//  YetiConstants.h
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#ifndef YetiConstants_h
#define YetiConstants_h

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#define YETI_EXPORT FOUNDATION_EXPORT

typedef NSString * FMNotification;

extern FMNotification _Nonnull const FeedDidUpReadCount;
extern FMNotification _Nonnull const FeedsDidUpdate;
extern FMNotification _Nonnull const UserDidUpdate;
extern FMNotification _Nonnull const BookmarksDidUpdate;
extern FMNotification _Nonnull const SubscribedToFeed;

YETI_EXPORT NSString * const kResetAccountSettingsPref;
YETI_EXPORT NSString * const kHasShownOnboarding;
YETI_EXPORT NSString * const kIsSubscribingToPushNotifications;

YETI_EXPORT NSString * const kDefaultsBackgroundRefresh;
YETI_EXPORT NSString * const kDefaultsNotifications;
YETI_EXPORT NSString * const kDefaultsImageLoading;
YETI_EXPORT NSString * const kDefaultsImageBandwidth;
YETI_EXPORT NSString * const kSubscriptionType;

YETI_EXPORT NSString * const kShowArticleCoverImages;

typedef NSString * ImageLoadingOption NS_STRING_ENUM;

YETI_EXPORT ImageLoadingOption const ImageLoadingLowRes;
YETI_EXPORT ImageLoadingOption const ImageLoadingMediumRes;
YETI_EXPORT ImageLoadingOption const ImageLoadingHighRes;

YETI_EXPORT ImageLoadingOption const ImageLoadingNever;
YETI_EXPORT ImageLoadingOption const ImageLoadingOnlyWireless;
YETI_EXPORT ImageLoadingOption const ImageLoadingAlways;

typedef NSString * ExternalAppsScheme;

YETI_EXPORT ExternalAppsScheme const ExternalTwitterAppScheme;
YETI_EXPORT ExternalAppsScheme const ExternalRedditAppScheme;
YETI_EXPORT ExternalAppsScheme const ExternalBrowserAppScheme;

typedef  NSString * YetiThemeType NS_STRING_ENUM;
YETI_EXPORT NSString * const kDefaultsTheme;

YETI_EXPORT YetiThemeType const LightTheme;
YETI_EXPORT YetiThemeType const DarkTheme;
YETI_EXPORT YetiThemeType const ReaderTheme;
YETI_EXPORT YetiThemeType const BlackTheme;

YETI_EXPORT NSNotificationName kWillUpdateTheme;
YETI_EXPORT NSNotificationName kDidUpdateTheme;

typedef NSString * ArticleLayoutPreference NS_STRING_ENUM;

YETI_EXPORT NSString * const kDefaultsArticleFont;
YETI_EXPORT ArticleLayoutPreference const ALPSerif;
YETI_EXPORT ArticleLayoutPreference const ALPSystem;
YETI_EXPORT ArticleLayoutPreference const ALPHelvetica;
YETI_EXPORT ArticleLayoutPreference const ALPMerriweather;
YETI_EXPORT ArticleLayoutPreference const ALPPlexSerif;
YETI_EXPORT ArticleLayoutPreference const ALPPlexSans;
YETI_EXPORT ArticleLayoutPreference const ALPSpectral;

typedef NSString * YetiSubscriptionType NS_STRING_ENUM;
YETI_EXPORT YetiSubscriptionType const YTSubscriptionMonthly;
YETI_EXPORT YetiSubscriptionType const YTSubscriptionYearly;

YETI_EXPORT NSString * const YTSubscriptionPurchased;
YETI_EXPORT NSString * const YTSubscriptionHasAddedFirstFeed;
YETI_EXPORT NSNotificationName YTSubscriptionHasExpiredOrIsInvalid;
YETI_EXPORT NSNotificationName YTUserPurchasedSubscription;

YETI_EXPORT NSString * const YTLaunchCountOldKey;
YETI_EXPORT NSString * const YTLaunchCount;
YETI_EXPORT NSString * const YTRequestedReview;

YETI_EXPORT NSString * const YTSubscriptionNotification;

YETI_EXPORT NSString * const kUseExtendedFeedLayout;

YETI_EXPORT NSString * const kShowUnreadCounts;
YETI_EXPORT NSNotificationName const ShowUnreadCountsPreferenceChanged;
YETI_EXPORT NSString * const kHideBookmarksTab;
YETI_EXPORT NSNotificationName const ShowBookmarksTabPreferenceChanged;
YETI_EXPORT NSString * const kOpenUnreadOnLaunch;
YETI_EXPORT NSString * const kShowTags;

YETI_EXPORT NSString * const kPreviewLines;

typedef NS_ENUM(NSInteger, FeedType) {
    FeedTypeFeed,
    FeedTypeCustom,
    FeedTypeFolder,
    FeedTypeTag
};

YETI_EXPORT NSString * const kUseImageProxy;

YETI_EXPORT NSString * const kDetailFeedSorting;
typedef NSString * YetiSortOption;
extern YetiSortOption const YTSortAllDesc;    // 0
extern YetiSortOption const YTSortAllAsc;     // 1
extern YetiSortOption const YTSortUnreadDesc; // 2
extern YetiSortOption const YTSortUnreadAsc;  // 3

extern NSString * const IAPOneMonth;
extern NSString * const IAPThreeMonth;
extern NSString * const IAPTwelveMonth;
extern NSString * const IAPLifetime;

YETI_EXPORT NSString * const kShowMarkReadPrompt;

extern BOOL canSupportOLED (void);

#define LOCAL_NAME_COLLECTION @"localNames"

@interface SortImageProvider : NSObject

+ (UIImage *)imageForSortingOption:(YetiSortOption)option;

@end

#endif /* YetiConstants_h */

#import "PrefsManager.h"
