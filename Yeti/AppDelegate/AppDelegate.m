//
//  AppDelegate.m
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+Routing.h"
#import "AppDelegate+Push.h"
#import "AppDelegate+Store.h"

#import <JLRoutes/JLRoutes.h>
#import "YetiThemeKit.h"

#import "YetiConstants.h"
#import "CodeParser.h"

#import <UserNotifications/UNUserNotificationCenter.h>

#import "SplitVC.h"
#import "YetiConstants.h"
#import "FeedsManager.h"

#ifdef DEBUG
#import <LinkPresentation/LinkPresentation.h>
#endif

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate () {
    BOOL _restoring;
}

- (BOOL)commonInit:(UIApplication *)application;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] init];
    
    BOOL retval = [self commonInit:application];
    
    return retval;
    
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    BOOL retval = [self commonInit:application];
    
    [self.window makeKeyAndVisible];
    
    return retval;
    
}

- (BOOL)commonInit:(UIApplication *)application {
    
    __block BOOL retval;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [self setupRouting];
        
        NSDictionary *defaults = [self performSelector:@selector(appDefaults)];
        
        if(defaults)
        {
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        }
        
        [self setupRootController];
        
        // Set app-wide shared cache (first number is megabyte value)
        NSUInteger cacheSizeMemory = 50*1024*1024; // 50 MB
        NSUInteger cacheSizeDisk = 500*1024*1024; // 500 MB
        NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
        [NSURLCache setSharedURLCache:sharedCache];
        
//        [SharedImageLoader.cache removeAllObjects];
//        [SharedImageLoader.cache removeAllObjectsFromDisk];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MyAppDelegate = self;
        });
        
        [application setMinimumBackgroundFetchInterval:(3600 * 2)]; // fetch once every 2 hours
        
//        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        
        weakify(self);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            strongify(self);
            
            [ADZLogger initialize];
            
            [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
            
            [self setupStoreManager];
        });
        
        if (MyFeedsManager.keychain[kIsSubscribingToPushNotifications]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [application registerForRemoteNotifications];
            });
        }
        
        [[UIImageView appearance] setAccessibilityIgnoresInvertColors:YES];
        
        [UIApplication registerObjectForStateRestoration:(id <UIStateRestoring>)MyFeedsManager restorationIdentifier:NSStringFromClass(FeedsManager.class)];
        
        // To test push notifications
        #ifdef DEBUG
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                strongify(self);
        
        //        [self openFeed:@(1) article:@(1293968)];  // twitter user
        //        [self openFeed:@(1) article:@(1273075)];  // twitter status
        //        [self openFeed:@(1) article:@(1149498)];  // reddit
//                [self openFeed:@(73) article:@(8301134)];
//                [self showArticle:@(1831527)]; // crashing article
            });
        #endif
        
//            [self yt_log_fontnames];
        
        //    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
        //    DDLogDebug(@"EX:%@", data);
        
        // did finish launching
#if !(TARGET_IPHONE_SIMULATOR)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [application registerForRemoteNotifications];
        });
#endif

        id countVal = MyFeedsManager.keychain[YTLaunchCount];
        
        NSInteger count = [(countVal ?: @0) integerValue];
        
        if (count == 0) {
            // remove the old key's items
            if ([YTLaunchCountOldKey length] > 0 ) {
                MyFeedsManager.keychain[YTLaunchCountOldKey] = nil;
            }
            
            MyFeedsManager.keychain[YTRequestedReview] = [@(NO) stringValue];
        }
        
        MyFeedsManager.keychain[YTLaunchCount] = [@(count + 1) stringValue];
        
        retval = YES;
        
        // from v1.2, this is the default.
        if ([NSUserDefaults.standardUserDefaults boolForKey:kUseExtendedFeedLayout] == NO) {
            [NSUserDefaults.standardUserDefaults setBool:YES forKey:kUseExtendedFeedLayout];
            [NSUserDefaults.standardUserDefaults synchronize];
        }
        
    });
    
    return retval;
    
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL reset = [defaults boolForKey:kResetAccountSettingsPref];
    
    if (reset) {
        [MyFeedsManager resetAccount];
        
        SplitVC *v = (SplitVC *)[[application keyWindow] rootViewController];
        [v userNotFound];
        
        [defaults setBool:NO forKey:kResetAccountSettingsPref];
        [defaults synchronize];
    }

}

#pragma mark - State Restoration

#define kFeedsManager @"FeedsManager"

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    
//    // broken in iOS 13.
////    if (@available(iOS 13, *)) {
//        return NO;
////    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    
//    // broken in iOS 13.
////    if (@available(iOS 13, *)) {
//        return NO;
////    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL reset = [defaults boolForKey:kResetAccountSettingsPref];
    
    if (reset) {
        return NO;
    }
    
    NSString *oldVersion = [coder decodeObjectForKey:UIApplicationStateRestorationBundleVersionKey];
    
    if (oldVersion) {
        NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        BOOL isNewer = ([currentVersion compare:oldVersion options:NSNumericSearch] == NSOrderedDescending);
        // don't restore across versions.
        if (isNewer) {
            return NO;
        }
    }
    
    UIDevice *currentDevice = [UIDevice currentDevice];
    UIUserInterfaceIdiom restorationInterfaceIdiom = [[coder decodeObjectForKey:UIApplicationStateRestorationUserInterfaceIdiomKey] integerValue];
    UIUserInterfaceIdiom currentInterfaceIdiom = currentDevice.userInterfaceIdiom;
    if (restorationInterfaceIdiom != currentInterfaceIdiom) {
        DDLogDebug(@"Ignoring restoration data for interface idiom: %@", @(restorationInterfaceIdiom));
        return NO;
    }
    
    _restoring = YES;
    
    DDLogDebug(@"Will restore application state");
    return _restoring;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    DDLogDebug(@"Application will save restoration data");
    
    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    DDLogDebug(@"Application did restore");
}

//- (UIViewController *)application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray <NSString *> *)identifierComponents coder:(NSCoder *)coder {
//    return nil;
//}

#pragma mark -

// logs all fonts loaded by the app
- (void)yt_log_fontnames {
    
    for (NSString* family in [UIFont familyNames])
    {
        NSLog(@"- %@", family);
        
        for (NSString* name in [UIFont fontNamesForFamilyName: family])
        {
            NSLog(@"\t|- %@", name);
        }
    }
}

#pragma mark - <DZAppDelegateProtocol>

- (NSDictionary *)appDefaults {
    return @{kDefaultsTheme: LightTheme,
             kDefaultsBackgroundRefresh: @YES,
             kDefaultsNotifications: @NO,
             kDefaultsImageLoading: ImageLoadingMediumRes,
             kDefaultsImageBandwidth: ImageLoadingAlways,
             kDefaultsArticleFont: ALPSystem,
             kSubscriptionType: @"None",
             kShowArticleCoverImages: @NO,
             kUseExtendedFeedLayout: @YES, // deprecated in v1.2.0
             kShowUnreadCounts: @YES,
             kUseImageProxy: @NO,
             kDetailFeedSorting: YTSortAllDesc,
             kShowMarkReadPrompt: @YES,
             kPreviewLines: @0,
             kShowTags: @YES,
             kUseToolbar: @NO
             };
}

- (void)setupRootController {
    
//    if (_restoring == YES) {
//        _restoring = NO;
//        return;
//    }
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    self.window.rootViewController = splitVC;
    
    [splitVC loadViewIfNeeded];
    
    NSString *themeName = SharedPrefs.theme;
    
    YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
    
    [self loadCodeTheme];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshViews) name:ThemeDidUpdate object:nil];
    
    [self refreshViews];
    
}

#pragma mark - Theming

- (void)loadCodeTheme {
    
    NSString *themeName = SharedPrefs.theme;
    
    if (@available(iOS 13, *)) {
        
        if (self.window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
            [CodeParser.sharedCodeParser loadTheme:@"dark"];
        }
        else {
            [CodeParser.sharedCodeParser loadTheme:themeName];
        }
        
    }
    else {
        [CodeParser.sharedCodeParser loadTheme:themeName];
    }
    
}

// https://ngs.io/2014/10/26/refresh-ui-appearance/

- (void)refreshViews {
    
    if ([NSThread isMainThread] == NO) {
        weakify(self);
        dispatch_async(dispatch_get_main_queue(), ^{
            strongify(self);
            [self refreshViews];
        });
        
        return;
    }
    // the following is handled within YetiTheme model
//    for (UIWindow *window in UIApplication.sharedApplication.windows) {
//        window.tintColor = YTThemeKit.theme.tintColor;
//    }

   [[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateTheme object:nil];
    
}

- (void)_checkWindows {
    
    for (UIWindow *testWindow in [UIApplication sharedApplication].windows) {
        DDLogDebug(@"Window: Level: %@; Hidden: %@; Class: %@", @(testWindow.windowLevel), @(testWindow.isHidden), NSStringFromClass(testWindow.class));
        if (!testWindow.opaque && [NSStringFromClass(testWindow.class) hasPrefix:@"UIText"]) {
            BOOL wasHidden = testWindow.hidden;
            testWindow.hidden = YES;

            if (!wasHidden) {
//                testWindow.hidden = NO;
            }

            break;
        }
    }

}

#pragma mark -

- (UINotificationFeedbackGenerator *)notificationGenerator {
    
    if (!_notificationGenerator) {
        _notificationGenerator = [[UINotificationFeedbackGenerator alloc] init];
        [_notificationGenerator prepare];
    }
    
    return _notificationGenerator;
    
}

#pragma mark -

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [JLRoutes routeURL:url];
}

- (void)application:(UIApplication *)app performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    
    BOOL backgroundRefresh = [NSUserDefaults.standardUserDefaults boolForKey:@"backgroundRefresh"];
    
    if (backgroundRefresh == NO) {
        completionHandler(UIBackgroundFetchResultNoData);
        return;
    }
    
    NSInteger currentCount = (ArticlesManager.shared.unread ?: @[]).count;
    
    [MyFeedsManager getUnreadForPage:1 sorting:@"0" success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
        if (responseObject == nil) {
            completionHandler(UIBackgroundFetchResultNoData);
            return;
        }
        
        if ([responseObject isKindOfClass:NSDictionary.class] == NO) {
            completionHandler(UIBackgroundFetchResultNoData);
            return;
        }
        
        NSInteger newCount = [[responseObject valueForKey:@"total"] integerValue];
        
        SplitVC *vc = (SplitVC *)(self.window.rootViewController);
        
        if (!vc) {
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }
        
        UINavigationController *nav = [[vc viewControllers] firstObject];
        
        if (!nav) {
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }
        
        FeedsVC *feeds = [[nav viewControllers] firstObject];
        
        if (!feeds) {
            completionHandler(UIBackgroundFetchResultNewData);
            return;
        }
        
        if (newCount > currentCount) {
            completionHandler(UIBackgroundFetchResultNewData);
            
            NSIndexSet *set = [NSIndexSet indexSetWithIndex:0];
            [feeds.tableView reloadSections:set withRowAnimation:UITableViewRowAnimationNone];
        }
        else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
        
        [feeds.refreshControl setAttributedTitle:[feeds lastUpdateAttributedString]];
        
    } error:^(NSError *error, NSHTTPURLResponse *response, NSURLSessionTask *task) {
       
        completionHandler(UIBackgroundFetchResultFailed);
        
    }];
    
}

@end
