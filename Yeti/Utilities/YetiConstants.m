//
//  YetiConstants.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiConstants.h"

NSString *const kHasShownOnboarding = @"com.yeti.onboarding.main";

#pragma mark - NSUserDefaults Keys

NSString * const kDefaultsBackgroundRefresh = @"backgroundRefresh";
NSString * const kDefaultsNotifications = @"notifications";
NSString * const kDefaultsImageLoading = @"imageLoading";
NSString * const kDefaultsImageBandwidth = @"imageBandwidth";

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

NSNotificationName YTDidPurchaseProduct = @"com.elytra.note.purchased";
NSNotificationName YTPurchaseProductFailed = @"com.elytra.note.purhcaseFailed";
