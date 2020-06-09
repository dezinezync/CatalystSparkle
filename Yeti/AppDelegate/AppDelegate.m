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

#import <DZTextKit/YetiConstants.h>
#import "CodeParser.h"

#import <UserNotifications/UNUserNotificationCenter.h>

#import "SplitVC.h"
#import <DZTextKit/YetiConstants.h>
#import "FeedsManager.h"
#import "Keychain.h"

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate () {
    BOOL _restoring;
    BOOL _resetting;
}

- (BOOL)commonInit:(UIApplication *)application;

@end

@implementation AppDelegate

//- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
//    
//    self.window = [[UIWindow alloc] init];
//    
//    BOOL retval = [self commonInit:application];
//    
//    return retval;
//    
//}
//
//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    
//    BOOL retval = [self commonInit:application];
//    
//    [self.window makeKeyAndVisible];
//    
//    return retval;
//    
//}

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(nonnull UISceneSession *)connectingSceneSession options:(nonnull UISceneConnectionOptions *)options {
    
    UISceneConfiguration *config = [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:UIWindowSceneSessionRoleApplication];
    config.delegateClass = AppDelegate.class;
    return config;
    
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    
    if ([scene isKindOfClass:UIWindowScene.class] == NO) {
        return;
    }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    
    __unused BOOL unused = [self commonInit:UIApplication.sharedApplication];
    
#if TARGET_OS_MACCATALYST
    [self ct_setupToolbar:windowScene];
    [self ct_setupAppKitBundle];
#endif
    
    [self.window makeKeyAndVisible];
    
}

- (BOOL)commonInit:(UIApplication *)application {
    
    __block BOOL retval;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        [self setupRouting];
        
        [self registerNotificationCategories];
        
        NSDictionary *defaults = [self performSelector:@selector(appDefaults)];
        
        if(defaults)
        {
            [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
        }
        
        [self setupRootController];
        
//        [SharedImageLoader.cache removeAllObjects];
//        [SharedImageLoader.cache removeAllObjectsFromDisk];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            MyAppDelegate = self;
        });
        
        if (SharedPrefs.backgroundRefresh == YES) {
            [self setupBackgroundRefresh];
        }
        
        weakify(self);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            strongify(self);
            
            [UNUserNotificationCenter currentNotificationCenter].delegate = (id <UNUserNotificationCenterDelegate>)self;
            
            [self setupStoreManager];
        });
        
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

- (void)applicationDidBecomeActive:(UIApplication *)application {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL reset = [defaults boolForKey:kResetAccountSettingsPref];
    
    _resetting = reset;
    
//#ifdef DEBUG
//    reset = YES;
//#endif
    
    if (reset) {
        [MyFeedsManager resetAccount];
        
        SplitVC *v = (SplitVC *)[UIApplication.keyWindow rootViewController];
        [v userNotFound];
        
        [defaults setBool:NO forKey:kResetAccountSettingsPref];
        [defaults synchronize];
    }

}

#pragma mark - State Restoration

#define kFeedsManager @"FeedsManager"

- (BOOL)application:(UIApplication *)application shouldSaveApplicationState:(NSCoder *)coder {
    
    return YES;
    
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    
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
    
    [coder encodeObject:MyFeedsManager forKey:kFeedsManager];
    [coder encodeObject:ArticlesManager.shared forKey:@"ArticlesManager"];
}

- (void)application:(UIApplication *)application didDecodeRestorableStateWithCoder:(NSCoder *)coder {
    NSLogDebug(@"Application did restore");
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
    
    [YetiThemeKit loadThemeKit];
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    self.window.rootViewController = splitVC;
    
    [splitVC loadViewIfNeeded];
    
    NSString *themeName = SharedPrefs.theme;
    
    YTThemeKit.theme = [YTThemeKit themeNamed:themeName];
    
    [self loadCodeTheme];
    
//    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshViews) name:ThemeDidUpdate object:nil];
    
    [self refreshViews];
    
}

#pragma mark - Theming

- (void)loadCodeTheme {
    
    NSString *themeName = SharedPrefs.theme;
    
    if (self.window.traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [CodeParser.sharedCodeParser loadTheme:@"dark"];
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
