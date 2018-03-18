//
//  YetiConstants.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/03/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import "YetiConstants.h"

#pragma mark - NSUserDefaults Keys

NSString * const kDefaultsTheme = @"theme";
NSString * const kDefaultsBackgroundRefresh = @"backgroundRefresh";
NSString * const kDefaultsNotifications = @"notifications";
NSString * const kDefaultsImageLoading = @"imageLoading";

#pragma mark - Image Loading

ImageLoadingOption const ImageLoadingLowRes = @"Low Res";
ImageLoadingOption const ImageLoadingMediumRes = @"Medium Res";
ImageLoadingOption const ImageLoadingHighRes = @"High Res";

#pragma mark - External Apps

ExternalAppsScheme const ExternalTwitterAppScheme = @"externalapp.twitter";
ExternalAppsScheme const ExternalRedditAppScheme = @"externalapp.reddit";
ExternalAppsScheme const ExternalBrowserAppScheme = @"externalapp.browser";
