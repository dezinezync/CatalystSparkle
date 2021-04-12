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

#import "YetiConstants.h"
#import "CodeParser.h"

#import <UserNotifications/UNUserNotificationCenter.h>

#import "YetiConstants.h"
#import "Keychain.h"

#import "PhotosController.h"
#import "Elytra-Swift.h"

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate () {
    BOOL _restoring;
    BOOL _resetting;
}

- (BOOL)commonInit:(UIApplication *)application;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [self commonInit:application];
    
    return YES;
    
}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(nonnull UISceneSession *)connectingSceneSession options:(nonnull UISceneConnectionOptions *)options {
    
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
    
    config.delegateClass = SceneDelegate.class;
    
    return config;
    
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}

- (BOOL)commonInit:(UIApplication *)application {
    
    __block BOOL retval;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        // code to debug state restoration as of iOS 13
//#ifdef DEBUG
//    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"UIStateRestorationDebugLogging"];
//    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"UIStateRestorationDeveloperMode"];
//#endif
        
        MyAppDelegate = self;
        
#if TARGET_OS_MACCATALYST
        [self ct_setupAppKitBundle];
#endif
        
        [self setupRouting];
        
        [self registerNotificationCategories];
        
        NSDictionary *defaults = [self performSelector:@selector(appDefaults)];
        
        if(defaults)
        {
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        }
        
        self.coordinator = [Coordinator new];
//#ifdef DEBUG
//        [self.coordinator resetAccountWithCompletion:nil];
//#endif
//        weakify(self);
        
        [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
        
#if TARGET_OS_MACCATALYST
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self.coordinator registerForNotificationsWithCompletion:nil];
            
        });
#endif
        
//#ifdef DEBUG
//        
//        NSDictionary *info = @{
//            @"types": @{@"article": @YES},
//            @"articleID": @"16895326"
//        };
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//            [self application:application didReceiveRemoteNotification:info fetchCompletionHandler:^(UIBackgroundFetchResult result) {
//                NSLog(@"Result: %@", @(result));
//            }];
//        });
//#endif
        
        [self setupStoreManager];
        
        if ([Keychain boolFor:kIsSubscribingToPushNotifications error:nil]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([application isRegisteredForRemoteNotifications] == YES) {
                    [application registerForRemoteNotifications];
                }
            });
        }
        
        [[UIImageView appearance] setAccessibilityIgnoresInvertColors:YES];
        
//         To test push notifications
//        #ifdef DEBUG
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//
////                [self openFeed:@(1) article:@(1293968)];  // twitter user
////                [self openFeed:@(1) article:@(18190949)];  // twitter status
////                [self openFeed:@(1) article:@(1149498)];  // reddit
////                [self openFeed:@(11139) article:@(11288965)]; //webp image
////                [self showArticle:@(1831527)]; // crashing article
////                [self showArticle:@(22316737)]; // breaklines article (patched on 15/02/2021 10:29AM)
////                [self showArticle:@(22589308)];
////                [self openFeed:@(11750) article:@(11311036)]; // youtube video
////                [self openFeed:@(18) article:@(17754118)]; // Elytra
////                [self openFeed:@(1) article:nil];
//            });
//        #endif
        
//            [self yt_log_fontnames];
        
        //    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
        //    NSLogDebug(@"EX:%@", data);
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
        
        NSString *countKey = [NSString stringWithFormat:@"launchCount-%@", appVersion];

        NSInteger count = [Keychain integerFor:countKey error:nil];
        
        [Keychain add:countKey integer:(count + 1)];
        
        retval = YES;
        
    });
    
    return retval;
    
}

#pragma mark -

#pragma mark - State Restoration

#define kFeedsManager @"FeedsManager"
#define kArticlesManager @"ArticlesManager"

- (BOOL)application:(UIApplication *)application shouldSaveSecureApplicationState:(nonnull NSCoder *)coder {

    return YES;

}

- (BOOL)application:(UIApplication *)application shouldRestoreSecureApplicationState:(nonnull NSCoder *)coder {

    if (_resetting) {
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
        NSLogDebug(@"Ignoring restoration data for interface idiom: %@", @(restorationInterfaceIdiom));
        return NO;
    }

    _restoring = YES;

    NSLogDebug(@"Will restore application state");
    return _restoring;
}

- (void)application:(UIApplication *)application willEncodeRestorableStateWithCoder:(NSCoder *)coder {

    NSLogDebug(@"Application will save restoration data");

//    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];
//    [coder encodeObject:ArticlesManager.shared forKey:@"ArticlesManager"];
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLogDebug(@"Application did restore");
}

- (nullable UIViewController *) application:(UIApplication *)application viewControllerWithRestorationIdentifierPath:(NSArray<NSString *> *)identifierComponents coder:(NSCoder *)coder {
    
    SceneDelegate * scene = (id)[[UIApplication.sharedApplication.connectedScenes.allObjects firstObject] delegate];
    
    return scene.coordinator.splitVC;
    
}

#pragma mark -

// logs all fonts loaded by the app
- (void)yt_log_fontnames {
    
#ifndef DEBUG
    return;
#endif
    
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
    NSMutableDictionary *dict =  @{kDefaultsTheme: LightTheme,
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
             kUseToolbar: @NO,
             kHideBars: @NO,
                                   OpenBrowserInReaderMode: @NO
    }.mutableCopy;
    
#if TARGET_OS_MACCATALYST
    dict[kUseSystemFontSize] = @NO;
    dict[kFontSize] = @(14.f);
    dict[MacKeyRefreshFeeds] = @"Manually";
    dict[MacKeyOpensBrowserInBackground] = @NO;
#endif
    
    return dict;
    
}

- (void)setupRootController {
    
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
    
}

- (void)_checkWindows {
    
    for (UIWindow *testWindow in [UIApplication sharedApplication].windows) {
        NSLogDebug(@"Window: Level: %@; Hidden: %@; Class: %@", @(testWindow.windowLevel), @(testWindow.isHidden), NSStringFromClass(testWindow.class));
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

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return [JLRoutes routeURL:url];
}

@end
