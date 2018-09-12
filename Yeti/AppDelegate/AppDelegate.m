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

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate () {
    BOOL _restoring;
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    
    // Set app-wide shared cache (first number is megabyte value)
    NSUInteger cacheSizeMemory = 50*1024*1024; // 50 MB
    NSUInteger cacheSizeDisk = 500*1024*1024; // 500 MB
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:@"nsurlcache"];
    [NSURLCache setSharedURLCache:sharedCache];
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyAppDelegate = self;
    });
    
    [application setMinimumBackgroundFetchInterval:(3600 * 2)]; // fetch once every 2 hours
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    __unused BOOL unused = [super application:application willFinishLaunchingWithOptions:launchOptions];
    
    weakify(self);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        strongify(self);
    
        [ADZLogger initialize];
        
        [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
        
        [self setupStoreManager];
    });
    
    if (MyFeedsManager.keychain[kIsSubscribingToPushNotifications]) {
        asyncMain(^{
            [application registerForRemoteNotifications];
        });
    }
    
    [[UIImageView appearance] setAccessibilityIgnoresInvertColors:YES];
    
    [UIApplication registerObjectForStateRestoration:(id <UIStateRestoring>)MyFeedsManager restorationIdentifier:NSStringFromClass(MyFeedsManager.class)];

    // To test push notifications
#ifdef DEBUG
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        strongify(self);
//
//        [self openFeed:@(18) article:@(97012)];
//    });
#endif
    
    //    [self yt_log_fontnames];
    
    //    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
    //    DDLogDebug(@"EX:%@", data);

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
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
    
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
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

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
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
    return YES;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {
    DDLogDebug(@"Application will save restoration data");
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    DDLogDebug(@"Application did restore");
}

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
    return @{kDefaultsTheme: @"light",
             kDefaultsBackgroundRefresh: @YES,
             kDefaultsNotifications: @NO,
             kDefaultsImageLoading: ImageLoadingMediumRes,
             kDefaultsImageBandwidth: ImageLoadingAlways,
             kDefaultsArticleFont: ALPSystem,
             kSubscriptionType: @"None",
             kShowArticleCoverImages: @NO
             };
}

- (void)setupRootController {
    
    if (_restoring == YES) {
        _restoring = NO;
        return;
    }
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    self.window.rootViewController = splitVC;
    
    [splitVC loadViewIfNeeded];
    
    NSString *theme = [[NSUserDefaults standardUserDefaults] valueForKey:kDefaultsTheme];
    NSString *themeName = nil;
    if ([theme isEqualToString:LightTheme]) {
        themeName = @"light";
    }
    else if ([theme isEqualToString:BlackTheme]) {
        themeName = @"black";
    }
    else {
        themeName = @"dark";
    }
    
    YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
    [CodeParser.sharedCodeParser loadTheme:themeName];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshViews) name:ThemeDidUpdate object:nil];
    
    [self refreshViews];
    
}

#pragma mark - Theming

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
    
    NSInteger currentCount = (MyFeedsManager.unread ?: @[]).count;
    
    [MyFeedsManager getUnreadForPage:1 success:^(id responseObject, NSHTTPURLResponse *response, NSURLSessionTask *task) {
        
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
