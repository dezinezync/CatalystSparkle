//
//  PrefsManager.h
//  Yeti
//
//  Created by Nikhil Nigade on 10/01/19.
//  Copyright © 2019 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YetiConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class PrefsManager;

extern PrefsManager * SharedPrefs;

/**
 Manages the global state of user preferences.
 Also responsible for dispatching notifications when these preferences change.
 All properties are mapped to NSUserDefaults and are read from it upon launch.
 */
@interface PrefsManager : NSObject

+ (instancetype)sharedInstance;

@property (copy) NSString *theme; // kDefaultsTheme
@property (assign) BOOL backgroundRefresh; // kDefaultsBackgroundRefresh
@property (assign) BOOL notifications; // kDefaultsNotifications
@property (copy) ImageLoadingOption imageLoading; // kDefaultsImageLoading
@property (copy) ImageLoadingOption imageBandwidth; // kDefaultsImageBandwidth
@property (copy) ArticleLayoutPreference articleFont; // kDefaultsArticleFont
@property (copy) NSString *subscriptionType; // kSubscriptionType
@property (assign) BOOL articleCoverImages; // kShowArticleCoverImages
@property (assign) BOOL showUnreadCounts; // kShowUnreadCounts
@property (assign) BOOL imageProxy; // kUseImageProxy
@property (copy) YetiSortOption sortingOption; // kDetailFeedSorting
@property (assign) BOOL showMarkReadPrompts; // kShowMarkReadPrompt
@property (assign) BOOL openUnread; // kOpenUnreadOnLaunch
@property (assign) BOOL hideBookmarks; // kHideBookmarksTab
@property (assign) NSInteger previewLines; // kPreviewLines
@property (assign) BOOL showTags; // kShowTags
@property (assign) BOOL useToolbar; // kUseToolbar

@end

NS_ASSUME_NONNULL_END
