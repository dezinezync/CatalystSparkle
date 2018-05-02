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

#define YETI_EXPORT FOUNDATION_EXPORT

YETI_EXPORT NSString * const kDefaultsBackgroundRefresh;
YETI_EXPORT NSString * const kDefaultsNotifications;
YETI_EXPORT NSString * const kDefaultsImageLoading;
YETI_EXPORT NSString * const kDefaultsImageBandwidth;

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
YETI_EXPORT YetiThemeType const BlackTheme;

YETI_EXPORT NSNotificationName kWillUpdateTheme;
YETI_EXPORT NSNotificationName kDidUpdateTheme;

typedef NSString * ArticleLayoutPreference NS_STRING_ENUM;

YETI_EXPORT NSString * const kDefaultsArticleFont;
YETI_EXPORT ArticleLayoutPreference const ALPSerif;
YETI_EXPORT ArticleLayoutPreference const ALPSystem;

#endif /* YetiConstants_h */
