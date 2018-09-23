//
//  YetiConstants.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiConstants.h"

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
YetiThemeType const BlackTheme = @"black";

NSNotificationName kWillUpdateTheme = @"com.yeti.note.willUpdateTheme";
NSNotificationName kDidUpdateTheme = @"com.yeti.note.didUpdateTheme";

#pragma mark - Article Layout

NSString * const kDefaultsArticleFont = @"articleFont";

ArticleLayoutPreference const ALPSerif = @"articlelayout.georgia";
ArticleLayoutPreference const ALPSystem = @"articlelayout.system";
ArticleLayoutPreference const ALPHelvetica = @"articlelayout.helveticaNeue";
ArticleLayoutPreference const ALPMerriweather = @"articlelayout.merriweather";
ArticleLayoutPreference const ALPPlexSerif = @"articlelayout.IBMPlexSerif";
ArticleLayoutPreference const ALPPlexSans = @"articlelayout.IBMPlexSans";
ArticleLayoutPreference const ALPSpectral = @"articlelayout.Spectral";

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
NSString * const YTLaunchCount = @"com.dezinezync.elytra.launchCount-1-0-0";
NSString * const YTRequestedReview = @"com.dezinezync.elytra.requestedReview";

NSString * const YTSubscriptionNotification = @"com.dezinezync.elytra.subscription";
