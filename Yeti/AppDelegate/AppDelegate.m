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

#import "SplitVC.h"
#import "YetiConstants.h"
#import "FeedsManager.h"
#import "Keychain.h"

#import "PhotosController.h"

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
        
//        [MyFeedsManager resetAccount];
        
        self.coordinator = [MainCoordinator new];
        
//        weakify(self);
        
        [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
        
#if TARGET_OS_MACCATALYST
        
        if ([[UIApplication sharedApplication] isRegisteredForRemoteNotifications] == NO) {
            
            [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionBadge|UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
                
                if (error) {
                    NSLog(@"Error authorizing for push notifications: %@",error);
                    return;
                }
                
                if (granted) {
                    
                    [Keychain add:kIsSubscribingToPushNotifications boolean:YES];
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIApplication.sharedApplication registerForRemoteNotifications];
                    });
                    
                }
            }];
            
        }
#endif
        
        [self setupStoreManager];
        
        if ([Keychain boolFor:kIsSubscribingToPushNotifications error:nil]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([application isRegisteredForRemoteNotifications] == YES) {
                    [application registerForRemoteNotifications];
                }
            });
        }
        
        [[UIImageView appearance] setAccessibilityIgnoresInvertColors:YES];
        
        if (MyFeedsManager != nil) {
            [UIApplication registerObjectForStateRestoration:(id <UIStateRestoring>)MyFeedsManager restorationIdentifier:NSStringFromClass(FeedsManager.class)];
        }
            
        if (ArticlesManager.shared != nil) {
            [UIApplication registerObjectForStateRestoration:(id <UIStateRestoring>)ArticlesManager.shared restorationIdentifier:NSStringFromClass(ArticlesManager.class)];
        }
        
//         To test push notifications
//        #ifdef DEBUG
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                strongify(self);
//
//        //        [self openFeed:@(1) article:@(1293968)];  // twitter user
//        //        [self openFeed:@(1) article:@(1273075)];  // twitter status
////                [self openFeed:@(1) article:@(1149498)];  // reddit
////                [self openFeed:@(11139) article:@(11288965)]; //webp image
////                [self showArticle:@(1831527)]; // crashing article
//                [self openFeed:@(11750) article:@(11311036)]; // youtube video
//            });
//        #endif
        
//            [self yt_log_fontnames];
        
        //    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
        //    NSLogDebug(@"EX:%@", data);
        
        // did finish launching
#if !(TARGET_IPHONE_SIMULATOR)
        
        weakify(application);
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            strongify(application);
            
            if ([application isRegisteredForRemoteNotifications] == YES) {
                
                [application registerForRemoteNotifications];
                
            }
        
        });
#endif

        NSInteger count = [Keychain integerFor:YTLaunchCount error:nil];
        
        [Keychain add:YTLaunchCount integer:(count + 1)];
        
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
    
    return scene.coordinator.splitViewController;
    
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

@end
