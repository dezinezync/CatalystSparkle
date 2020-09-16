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

#import "LayoutConstants.h"

#define YETI_EXPORT FOUNDATION_EXPORT

typedef NSNotificationName FMNotification;

extern FMNotification _Nonnull const UserNotFound;
extern FMNotification _Nonnull const FeedDidUpReadCount;
extern FMNotification _Nonnull const FeedsDidUpdate;
extern FMNotification _Nonnull const UnreadCountDidUpdate;
extern FMNotification _Nonnull const TodayCountDidUpdate;
extern FMNotification _Nonnull const UserDidUpdate;
extern FMNotification _Nonnull const BookmarksDidUpdate;
extern FMNotification _Nonnull const SubscribedToFeed;

YETI_EXPORT NSString * _Nonnull const kResetAccountSettingsPref;
YETI_EXPORT NSString * _Nonnull const kHasShownOnboarding;
YETI_EXPORT NSString * _Nonnull const kIsSubscribingToPushNotifications;

YETI_EXPORT NSString * _Nonnull const kDefaultsBackgroundRefresh;
YETI_EXPORT NSString * _Nonnull const kDefaultsNotifications;
YETI_EXPORT NSString * _Nonnull const kDefaultsImageLoading;
YETI_EXPORT NSString * _Nonnull const kDefaultsImageBandwidth;
YETI_EXPORT NSString * _Nonnull const kSubscriptionType;

YETI_EXPORT NSString * _Nonnull const kShowArticleCoverImages;

typedef NSString * ImageLoadingOption NS_STRING_ENUM;

YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingLowRes;
YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingMediumRes;
YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingHighRes;

YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingNever;
YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingOnlyWireless;
YETI_EXPORT ImageLoadingOption _Nonnull const ImageLoadingAlways;

typedef NSString * ExternalAppsScheme;

YETI_EXPORT ExternalAppsScheme _Nonnull const ExternalTwitterAppScheme;
YETI_EXPORT ExternalAppsScheme _Nonnull const ExternalRedditAppScheme;
YETI_EXPORT ExternalAppsScheme _Nonnull const ExternalBrowserAppScheme;

typedef  NSString * YetiThemeType NS_STRING_ENUM;
YETI_EXPORT NSString * _Nonnull const kDefaultsTheme;

YETI_EXPORT YetiThemeType _Nonnull const LightTheme;
YETI_EXPORT YetiThemeType _Nonnull const DarkTheme;
YETI_EXPORT YetiThemeType _Nonnull const ReaderTheme;
YETI_EXPORT YetiThemeType _Nonnull const BlackTheme;

YETI_EXPORT NSNotificationName _Nonnull kWillUpdateTheme;
YETI_EXPORT NSNotificationName _Nonnull kDidUpdateTheme;

typedef NSString * _Nonnull ArticleLayoutPreference NS_STRING_ENUM;
typedef NSString * _Nonnull ArticleLayoutFont NS_STRING_ENUM;

YETI_EXPORT NSString * _Nonnull const kDefaultsArticleFont;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPSerif;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPSystem;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPHelvetica;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPMerriweather;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPPlexSerif;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPPlexSans;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPSpectral;
YETI_EXPORT ArticleLayoutFont _Nonnull const ALPOpenDyslexic;

typedef NSString * YetiSubscriptionType NS_STRING_ENUM;
YETI_EXPORT YetiSubscriptionType _Nonnull const YTSubscriptionMonthly;
YETI_EXPORT YetiSubscriptionType _Nonnull const YTSubscriptionYearly;

YETI_EXPORT NSString * _Nonnull const YTSubscriptionPurchased;
YETI_EXPORT NSString * _Nonnull const YTSubscriptionHasAddedFirstFeed;
YETI_EXPORT NSNotificationName _Nonnull YTSubscriptionHasExpiredOrIsInvalid;
YETI_EXPORT NSNotificationName _Nonnull YTUserPurchasedSubscription;

YETI_EXPORT NSString * _Nonnull const YTLaunchCountOldKey;
YETI_EXPORT NSString * _Nonnull const YTLaunchCount;
YETI_EXPORT NSString * _Nonnull const YTRequestedReview;

YETI_EXPORT NSString * _Nonnull const YTSubscriptionNotification;

YETI_EXPORT NSString * _Nonnull const kUseExtendedFeedLayout;

YETI_EXPORT NSString * _Nonnull const kShowUnreadCounts;
YETI_EXPORT NSNotificationName _Nonnull const ShowUnreadCountsPreferenceChanged;
YETI_EXPORT NSString * _Nonnull const kHideBookmarksTab;
YETI_EXPORT NSNotificationName _Nonnull const ShowBookmarksTabPreferenceChanged;
YETI_EXPORT NSString * _Nonnull const kOpenUnreadOnLaunch;
YETI_EXPORT NSString * _Nonnull const kShowTags;
YETI_EXPORT NSString * _Nonnull const kUseToolbar;
YETI_EXPORT NSString * _Nonnull const kHideBars;

YETI_EXPORT NSString * _Nonnull const kPreviewLines;

YETI_EXPORT NSString * _Nonnull const kUseSystemFontSize;
YETI_EXPORT NSString * _Nonnull const kFontSize;
YETI_EXPORT NSString * _Nonnull const kParagraphTitleFont;
YETI_EXPORT NSString * _Nonnull const kLineSpacing;

extern NSNotificationName _Nonnull UserUpdatedPreferredFontMetrics;

typedef NS_ENUM(NSInteger, FeedType) {
    FeedTypeFeed,
    FeedTypeCustom,
    FeedTypeFolder,
    FeedTypeTag
};

YETI_EXPORT NSString * _Nonnull const kUseImageProxy;

YETI_EXPORT NSString * _Nonnull const kDetailFeedSorting;
typedef NSString * YetiSortOption;
extern YetiSortOption const _Nonnull YTSortAllDesc;    // 0
extern YetiSortOption const _Nonnull YTSortAllAsc;     // 1
extern YetiSortOption const _Nonnull YTSortUnreadDesc; // 2
extern YetiSortOption const _Nonnull YTSortUnreadAsc;  // 3

extern NSString * _Nonnull const IAPOneMonth;
extern NSString * _Nonnull const IAPThreeMonth;
extern NSString * _Nonnull const IAPTwelveMonth;
extern NSString * _Nonnull const IAPLifetime;
extern NSString * _Nonnull const IAPMonthlyAuto;
extern NSString * _Nonnull const IAPYearlyAuto;

YETI_EXPORT NSString * _Nonnull const kShowMarkReadPrompt;

extern BOOL canSupportOLED (void);

@interface SortImageProvider : NSObject

+ (UIImage * _Nullable)imageForSortingOption:(YetiSortOption _Nonnull)option tintColor:(UIColor *_Nullable* _Nullable)returnColor;

+ (UIColor * _Nullable)tintColorForSortingOption:(YetiSortOption _Nonnull)option;

@end

FOUNDATION_EXPORT void runOnMainQueueWithoutDeadlocking(void (^ _Nonnull block)(void));

#endif /* YetiConstants_h */
