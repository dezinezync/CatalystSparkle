//
//  YetiConstants.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiConstants.h"

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

YetiTheme const LightTheme = @"light";
YetiTheme const DarkTheme = @"dark";

NSNotificationName kWillUpdateTheme = @"com.yeti.note.willUpdateTheme";
NSNotificationName kDidUpdateTheme = @"com.yeti.note.didUpdateTheme";

#pragma mark - Article Layout

NSString * const kDefaultsArticleFont = @"articleFont";

ArticleLayoutPreference const ALPSerif = @"articlelayout.serifs";
ArticleLayoutPreference const ALPSystem = @"articlelayout.system";
