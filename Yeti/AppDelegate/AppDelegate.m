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
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyAppDelegate = self;
    });
    
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

    // To test push notifications
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        strongify(self);
//
//        [self openFeed:@(18) article:@(97012)];
//    });
    
    //    [self yt_log_fontnames];
    
    //    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
    //    DDLogDebug(@"EX:%@", data);

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
#ifndef TARGET_OS_SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [application registerForRemoteNotifications];
    });
#endif
    
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
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    DDLogDebug(@"Will save application state for version: %@", version);
    [coder encodeObject:version forKey:@"version"];
    return YES;
}

- (BOOL)application:(UIApplication *)application shouldRestoreApplicationState:(NSCoder *)coder {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    BOOL reset = [defaults boolForKey:kResetAccountSettingsPref];
    
    if (reset) {
        return NO;
    }
    
    NSString *oldVersion = [coder decodeObjectForKey:@"version"];
    
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
    [MyCodeParser loadTheme:themeName];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(refreshViews) name:ThemeNeedsUpdateNotification object:nil];
    
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
    
    for (UIWindow *window in UIApplication.sharedApplication.windows) {
        window.tintColor = YTThemeKit.theme.tintColor;
    }

   [[NSNotificationCenter defaultCenter] postNotificationName:kDidUpdateTheme object:nil];
    
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
