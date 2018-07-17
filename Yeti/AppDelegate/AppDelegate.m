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
#import "FeedsVC.h"

#import <JLRoutes/JLRoutes.h>
#import "YetiThemeKit.h"

#import "YetiConstants.h"
#import "EmptyVC.h"
#import "CodeParser.h"

#import <UserNotifications/UNUserNotificationCenter.h>

#import "SplitVC.h"
#import "YTNavigationController.h"
#import "YetiConstants.h"
#import "FeedsManager.h"

AppDelegate *MyAppDelegate = nil;

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        MyAppDelegate = self;
    });
    
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

    // To test push notifications
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        strongify(self);
//
//        [self openFeed:@(18) article:@(97012)];
//    });

    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
//    [self yt_log_fontnames];
    
    // Override point for customization after application launch.
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
#ifndef TARGET_OS_SIMULATOR
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [application registerForRemoteNotifications];
    });
#endif
    
//    NSString *data = [[@"highlightRowAtIndexPath:animated:scrollPosition:" dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:kNilOptions];
//    DDLogDebug(@"EX:%@", data);
    
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
    
    FeedsVC *vc = [[FeedsVC alloc] initWithStyle:UITableViewStylePlain];
    EmptyVC *vc2 = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    
    YTNavigationController *nav1 = [[YTNavigationController alloc] initWithRootViewController:vc];
    
    SplitVC *splitVC = [[SplitVC alloc] init];
    
    if (self.window.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        YTNavigationController *nav2 = [[YTNavigationController alloc] initWithRootViewController:vc2];
        vc2.navigationItem.leftBarButtonItem = splitVC.displayModeButtonItem;
        splitVC.viewControllers = @[nav1, nav2];
    }
    else {
        splitVC.viewControllers = @[nav1];
        vc2 = nil;
    }
    
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
