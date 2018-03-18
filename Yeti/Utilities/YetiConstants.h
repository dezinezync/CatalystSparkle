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

YETI_EXPORT NSString * const kDefaultsTheme;
YETI_EXPORT NSString * const kDefaultsBackgroundRefresh;
YETI_EXPORT NSString * const kDefaultsNotifications;
YETI_EXPORT NSString * const kDefaultsImageLoading;

typedef NSString * ImageLoadingOption NS_STRING_ENUM;

YETI_EXPORT ImageLoadingOption const ImageLoadingLowRes;
YETI_EXPORT ImageLoadingOption const ImageLoadingMediumRes;
YETI_EXPORT ImageLoadingOption const ImageLoadingHighRes;

typedef NSString * ExternalAppsScheme;

YETI_EXPORT ExternalAppsScheme const ExternalTwitterAppScheme;
YETI_EXPORT ExternalAppsScheme const ExternalRedditAppScheme;
YETI_EXPORT ExternalAppsScheme const ExternalBrowserAppScheme;

#endif /* YetiConstants_h */
