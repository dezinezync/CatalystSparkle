//
//  Coordinator.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "Coordinator.h"
#import <objc/runtime.h>

#import "AppDelegate.h"

#import "NewFolderVC.h"
#import "LaunchVC.h"
#import "StoreVC.h"
#import "NewFolderController.h"
#import "SettingsVC.h"
#import <DZKit/AlertManager.h>
#import "OPMLVC.h"
#import <DZKit/DZMessagingController.h>
#import <sys/utsname.h>
#import <UserNotifications/UserNotifications.h>
#import "Keychain.h"
#import "PrefsManager.h"

#import "Elytra-Swift.h"
#import "ArticleVC.h"

NSString* deviceName(void) {
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine
                              encoding:NSUTF8StringEncoding];
}

@interface MainCoordinator ()

@property (nonatomic, strong) NewFolderController *folderController;
@property (nonatomic, strong) NSTimer *registerNotificationsTimer;

@end

@implementation MainCoordinator

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.childCoordinators = [NSMutableArray arrayWithCapacity:3];
        
    }
    
    return self;
    
}

- (void)start {
    
    if (self.splitViewController == nil) {
        NSAssert(self.splitViewController != nil, @"A split view controller is needed to start the coordinator.");
    }
    
    SidebarVC *sidebar = [[SidebarVC alloc] init];
    sidebar.mainCoordinator = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sidebar];
    sidebar.navigationController.navigationBar.prefersLargeTitles = YES;
    sidebar.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnCompact];
    }

    [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnPrimary];
    
    self.sidebarVC = sidebar;
    
    UITraitCollection *traitCollection = UIApplication.sharedApplication.windows.firstObject.traitCollection;
    
    BOOL showUnread = SharedPrefs.openUnread;
    BOOL showEmpty = NO;
    
    if (traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPhone
        && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomMac) {
            
            showUnread = showUnread || YES;
            
        }
        
        showEmpty = YES;
        
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
       
        if (showUnread) {
            // @TODO
//            CustomFeed *feed = [[CustomFeed alloc] init];
//            feed.feedType = FeedVCTypeUnread;
//
//            [self showCustomVC:feed];
            
        }
        
        if (showEmpty) {
            
            EmptyVC *emptyVC = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
         
            [self.splitViewController setViewController:emptyVC forColumn:UISplitViewControllerColumnSecondary];
            
        }
        
        [self checkForPushNotifications];
        
    });
    
}

- (void)showCustomVC:(CustomFeed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    if (feed.feedType == FeedTypeUnread && (self.feedVC == nil || [self.feedVC isKindOfClass:UnreadVC.class] == NO)) {

        if (self.feedVC != nil) {
            self.feedVC = nil;
        }

        UnreadVC *unreadVC = [[UnreadVC alloc] init];

        [self _showSupplementaryController:unreadVC];

    }
    else if (feed.feedType == FeedTypeToday) {

        TodayVC *todayVC = [[TodayVC alloc] init];

        [self _showSupplementaryController:todayVC];

    }
//    else if (feed.feedType == FeedVCTypeBookmarks) {
//
//        BookmarksVC *bookmarksVC = [[BookmarksVC alloc] init];
//
//        [self _showSupplementaryController:bookmarksVC];
//
//    }
    
}

- (void)showFeedVC:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    // @TODO
    FeedVC *vc = [[FeedVC alloc] initWithStyle:UITableViewStylePlain];
    vc.feed = feed;
    vc.mainCoordinator = self;

    [self _showSupplementaryController:vc];
    
}

- (void)showFolderFeed:(Folder *)folder {
    
    if (folder == nil) {
        return;
    }
    
    FolderVC *vc = [FolderVC new];
    vc.folder = folder;

    [self _showSupplementaryController:vc];
    
}

- (void)showArticleVC:(ArticleVC *)articleVC {
    
    if (articleVC == nil) {
        return;
    }
    
    articleVC.mainCoordinator = self;
    
    if (self.feedVC != nil) {
        articleVC.providerDelegate = self.feedVC;
    }

    [self _showDetailController:articleVC];

    if (self.splitViewController.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomMac
        && self.splitViewController.view.bounds.size.width < 1024.f) {

        dispatch_async(dispatch_get_main_queue(), ^{

            [UIView animateWithDuration:0.125 animations:^{

                [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeSecondaryOnly];

            }];

        });

    }
    
}

- (void)showArticle:(Article *)article {
    
    ArticleVC *vc = [[ArticleVC alloc] initWithItem:article];
    
    [self showArticleVC:vc];
    
}

- (void)showEmptyVC {
    
    EmptyVC *vc = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    
    [self _showDetailController:vc];
    
}

- (void)showLaunchVC {
    
    if (self.splitViewController.presentingViewController != nil) {
        return;
    }
    
    LaunchVC *vc = [[LaunchVC alloc] initWithNibName:@"LaunchVC" bundle:nil];
    vc.mainCoordinator = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPhone && self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
        
    }
    else {
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    
    nav.modalInPresentation = YES;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
}

- (void)showSubscriptionsInterface {
    
#if TARGET_OS_MACCATALYST
    
    [self openSceneNamed:@"subscriptionInterface"];
    
    return;
    
#endif
    
    StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalInPresentation = YES;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(didTapDone:)];
    
    vc.navigationItem.rightBarButtonItem = done;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
}

- (void)showNewFeedVC {
    
#if TARGET_OS_MACCATALYST
    
    [self openSceneNamed:@"newFeedScene"];
    
#else
    
    NewFeedVC *vc = [[NewFeedVC alloc] initWithCollectionViewLayout:NewFeedVC.gridLayout];
    vc.mainCoordinator = self;
    vc.moveFoldersDelegate = self.sidebarVC;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
#endif
    
}

- (void)showNewFolderVC {
    
    if (self.folderController != nil && self.folderController.completed == NO) {
        return;
    }
    
    self.folderController = [[NewFolderController alloc] initWithFolder:nil coordinator:self completion:^(Folder * _Nullable folder, BOOL completed, NSError * _Nullable error) {
       
        if (error != nil) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Creating New Folder" message:error.localizedDescription];
            
        }
        else if (completed) {
            
            [self.sidebarVC setupData];
            
        }
        
    }];
    
    [self.folderController start];
    
}

- (void)showRenameFolderVC:(Folder *)folder {
    
    if (self.folderController != nil && self.folderController.completed == NO) {
        return;
    }
    
    self.folderController = [[NewFolderController alloc] initWithFolder:folder coordinator:self completion:^(Folder * _Nullable folder, BOOL completed, NSError * _Nullable error) {
       
        if (error != nil) {
            
            [AlertManager showGenericAlertWithTitle:@"Error Updating Folder" message:error.localizedDescription];
            
        }
        else if (completed) {
            
            [self.sidebarVC setupData];
            
        }
        
    }];
    
    [self.folderController start];
    
}

- (void)showSettingsVC {
    
    SettingsVC *settingsVC = [[SettingsVC alloc] initWithNibName:NSStringFromClass(SettingsVC.class) bundle:nil];
    
    settingsVC.mainCoordinator = self;
    
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    
#if TARGET_OS_MACCATALYST
    [self.splitViewController setViewController:navVC forColumn:UISplitViewControllerColumnSupplementary];
    
    [self showEmptyVC];
    
    self.emptyVC.label.text = @"Select a preferences section.";
    
    if (self.feedVC) {
        self.feedVC = nil;
    }
    
    if (self.articleVC) {
        self.articleVC = nil;
    }
    
#else
    [self.splitViewController presentViewController:navVC animated:YES completion:nil];
#endif
    
}

- (void)showOPMLInterfaceFrom:(id)sender direct:(NSInteger)type {
    
    OPMLVC *vc = [[OPMLVC alloc] initWithNibName:NSStringFromClass(OPMLVC.class) bundle:nil];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationAutomatic;
    
    if (sender != nil) {
        
        [sender presentViewController:nav animated:YES completion:^{
            
            if (type == OPMLStateExport) {
                [vc didTapExport:nil];
            }
            else if (type == OPMLStateImport) {
                [vc didTapImport:nil];
            }
            
        }];
        
    }
    else {
        
        [self.splitViewController presentViewController:nav animated:YES completion:^{
            
            if (type == OPMLStateExport) {
                [vc didTapExport:nil];
            }
            else if (type == OPMLStateImport) {
                [vc didTapImport:nil];
            }
            
        }];
        
    }
    
}

#if TARGET_OS_MACCATALYST

- (void)showAttributions {

    [self openSceneNamed:@"attributionsScene"];
    
}

- (void)openSceneNamed:(NSString *)sceneName {
    
    UISceneActivationRequestOptions * options = [UISceneActivationRequestOptions new];
    options.requestingScene = self.splitViewController.view.window.windowScene;
    options.collectionJoinBehavior = UISceneCollectionJoinBehaviorDisallowed;
    
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:sceneName];
    
    [UIApplication.sharedApplication requestSceneSessionActivation:nil userActivity:activity options:options errorHandler:^(NSError * _Nonnull error) {
        
        if (error != nil) {
            
            NSLog(@"Error occurred requesting new window session. %@", error.localizedDescription);
            
        }
        
    }];
    
}
    
#endif

- (void)showContactInterface {
    
//    NSURL *url = [NSURL URLWithString:@"mailto:support@elytra.app?subject=Elytra%20Support"];
    // @TODO:
//    DZMessagingAttachment *attachment = [[DZMessagingAttachment alloc] init];
//    attachment.fileName = @"debugInfo.txt";
//    attachment.mimeType = @"text/plain";
//    
//    UIDevice *device = [UIDevice currentDevice];
//    NSString *model = deviceName();
//    NSString *iOSVersion = formattedString(@"%@ %@", device.systemName, device.systemVersion);
//    NSString *deviceUUID = MyFeedsManager.deviceID;
//    
//    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
//    NSString *appVersion = [infoDict objectForKey:@"CFBundleShortVersionString"];
//    NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
//    
//    NSString *formatted = formattedString(@"Model: %@ %@\nDevice UUID: %@\nAccount ID: %@\nApp: %@ (%@)", model, iOSVersion, deviceUUID, MyFeedsManager.user.uuid, appVersion, buildNumber);
//    
//    attachment.data = [formatted dataUsingEncoding:NSUTF8StringEncoding];
//    
//    [DZMessagingController presentEmailWithBody:@""
//                                        subject:@"Elytra Support"
//                                     recipients:@[@"support@elytra.app"]
//                                    attachments:@[attachment]
//                                 fromController:self.splitViewController];
    
}

- (void)showFeedInfo:(id)feed from:(UIViewController *)viewController {
    
    FeedInfoController *instance = [[FeedInfoController alloc] initWithFeed:feed];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:instance];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [viewController presentViewController:nav animated:YES completion:nil];
    
}

#pragma mark - Resync

- (void)prepareDataForFullResync {
    
    SidebarVC *instance = self.sidebarVC;
    
    if (instance != nil) {
        
        // @TODO: [DBManager.sharedInstance purgeDataForResync];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.625 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
//                [instance performSelector:NSSelectorFromString(@"") withObject:instance.refreshControl];
            
            // @TODO: [instance beginRefreshingAll:instance.refreshControl];
            
        });
        
    }
    
}

- (void)prepareFeedsForFullResync {
    
    SidebarVC *instance = self.sidebarVC;
    
    if (instance != nil) {
        
        // @TODO: [DBManager.sharedInstance purgeFeedsForResync];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
//                [instance performSelector:NSSelectorFromString(@"") withObject:instance.refreshControl];
            
            // @TODO: [instance beginRefreshingAll:instance.refreshControl];
            
        });
        
    }
    
}

- (void)registerForNotifications:(void (^)(BOOL, NSError * _Nullable))completion {
    
    BOOL isImmediate = [NSThread.callStackSymbols.description containsString:@"PushRequestVC"];
    
    runOnMainQueueWithoutDeadlocking(^{
        
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            
            if (completion) {
                completion(YES, nil);
            }
            
            return;
        }
        
        if (UIApplication.sharedApplication.isRegisteredForRemoteNotifications == YES) {
            
            if (completion) {
                completion(YES, nil);
            }
            
            return;
        }
        
        [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
           
            if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                // no permission, ignore.
                
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(NO, nil);
                    });
                }
                
                return;
            }
            else if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                // no requested yet. Ask
                
                if (self.registerNotificationsTimer != nil) {
                    
                    if (self.registerNotificationsTimer.isValid) {
                        [self.registerNotificationsTimer invalidate];
                    }
                    
                    self.registerNotificationsTimer = nil;
                    
                }
                
                NSTimeInterval time = isImmediate ? 0 : 2;
                
                runOnMainQueueWithoutDeadlocking(^{
                    
                    self.registerNotificationsTimer = [NSTimer scheduledTimerWithTimeInterval:time repeats:NO block:^(NSTimer * _Nonnull timer) {
                       
                        [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:UNAuthorizationOptionBadge|UNAuthorizationOptionAlert|UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
                            
                            if (error) {
                                NSLog(@"Error authorizing for push notifications: %@", error);
                            }
                            
                            else if (granted) {
                                
                                [Keychain add:kIsSubscribingToPushNotifications boolean:YES];
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    [UIApplication.sharedApplication registerForRemoteNotifications];
                                });
                                
                            }
                            
                            if (completion) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    completion(granted, error);
                                });
                            }
                            
                        }];
                        
                    }];
                    
                });
                
            }
            else {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(YES, nil);
                    });
                }
            }
            
        }];
        
    });
    
}

- (void)checkForPushNotifications {
    
    runOnMainQueueWithoutDeadlocking(^{
        // @TODO
//        BOOL didAsk = [NSUserDefaults.standardUserDefaults boolForKey:@"pushRequest"];
//
//        if (didAsk) {
//            return;
//        }
//
//        if (MyFeedsManager.user == nil || MyFeedsManager.user.userID == nil) {
//            return;
//        }
//
//        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
//            return;
//        }
//
//        if (UIApplication.sharedApplication.isRegisteredForRemoteNotifications == YES) {
//            return;
//        }
//
//        [UNUserNotificationCenter.currentNotificationCenter getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
//
//            if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
//                // no permission, ignore.
//                return;
//            }
//            else if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
//
//                dispatch_async(dispatch_get_main_queue(), ^{
//
//                    PushRequestVC *vc = [[PushRequestVC alloc] initWithNibName:@"PushRequestVC" bundle:nil];
//                    vc.mainCoordinator = self;
//                    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
//
//                    [self.splitViewController presentViewController:vc animated:YES completion:nil];
//
//                });
//
//            }
//
//        }];
        
    });
    
}

- (void)didTapCloseForPushRequest {
    
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:@"pushRequest"];
    [NSUserDefaults.standardUserDefaults synchronize];
    
}

#pragma mark - Shared Containers

- (NSURL *)sharedContainerURL {
    
    return [NSFileManager.defaultManager containerURLForSecurityApplicationGroupIdentifier:@"group.elytra"];
    
}

- (void)writeToSharedFile:(NSString *)fileName data:(NSData *)data {
    
    NSURL * baseURL = self.sharedContainerURL;
    
    NSURL *fileURL = [baseURL URLByAppendingPathComponent:fileName];
    
    NSFileManager *fileManager = NSFileManager.defaultManager;
    
    NSString *path = fileURL.filePathURL.path;
    
    NSError *error = nil;
    
    if ([fileManager fileExistsAtPath:path]) {
        // first remove the existing file
        NSLogDebug(@"Removing existing file from: %@", path);
        
        if ([fileManager removeItemAtPath:path error:&error] == NO) {
            
            NSLog(@"Error removing file: %@\nError: %@", path, error.localizedDescription);
            
            return;
        }
        
    }
    
    if (data == nil) {
        return;
    }
    
//    NSData *dataRep = [NSJSONSerialization dataWithJSONObject:data options:kNilOptions error:&error];
//
//    if (error != nil) {
//
//        NSLog(@"Error serialising data: %@", error.localizedDescription);
//        return;
//
//    }
//
//    if (dataRep == nil) {
//        return;
//    }
    
    if ([data writeToFile:path atomically:YES] == NO) {
        
        NSLog(@"Failed to write data to %@", path);
        
    }
    
}

#pragma mark - Helpers

- (void)_showSupplementaryController:(UIViewController *)controller {
    
    if (controller == nil) {
        return;
    }
    
#if TARGET_OS_MACCATALYST
    
    if (self.innerWindow == nil) {

        id nsWindow = [[[[MyAppDelegate mainScene] windows] firstObject] innerWindow];

        if (nsWindow == nil) {
            // try again in 1s

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                id __nsWindow = [[[[MyAppDelegate mainScene] windows] firstObject] innerWindow];

                if (__nsWindow != nil) {

                    self.innerWindow = __nsWindow;

                    if (self.feedVC != nil) {
                        [self.feedVC updateTitleView];
                    }

                }

            });

        }

        self.innerWindow = nsWindow;

    }
#endif
    
    if ([controller isKindOfClass:FeedVC.class]) {

        self.feedVC = (FeedVC *)controller;

    }

    if ([controller isKindOfClass:UINavigationController.class] == NO) {

        controller.mainCoordinator = self;

    }

    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        && self.splitViewController.traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPhone) {

        if ([controller isKindOfClass:UINavigationController.class]) {

            [self.splitViewController setViewController:controller forColumn:UISplitViewControllerColumnSupplementary];

        }
        else {

            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];

            [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnSupplementary];

        }

        return;

    }

    UINavigationController *nav = self.splitViewController.viewControllers.firstObject;

    [nav pushViewController:controller animated:YES];
    
}

- (void)_showDetailController:(UIViewController *)controller {
    
    if (controller == nil) {
        return;
    }
    
//    if ([controller isKindOfClass:ArticleVC.class]) {
//        
//        self.articleVC = (ArticleVC *)controller;
//        
//    }
    
    BOOL isEmptyVC = NO;
    
    if ([controller isKindOfClass:EmptyVC.class]) {
        
        self.emptyVC = (EmptyVC *)controller;
        
        isEmptyVC = YES;
        
    }
    
    if (self.splitViewController.presentedViewController != nil && [self.splitViewController.presentedViewController isKindOfClass:UINavigationController.class]) {
        // in a modal stack
        [(UINavigationController *)[self.splitViewController presentedViewController] pushViewController:controller animated:YES];
    }
    else if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:controller];

        [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnSecondary];
        
    }
    else {
        
        // We never push the empty VC on the navigation stack
        // on compact devices
        if (isEmptyVC) {
            self.emptyVC = nil;
            return;
        }
        
        UINavigationController *nav = self.splitViewController.viewControllers.firstObject;
        [nav pushViewController:controller animated:YES];
        
    }
    
    if (self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        if ([self.splitViewController isCollapsed] == NO
            && self.splitViewController.displayMode == UISplitViewControllerDisplayModeTwoDisplaceSecondary) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
               
                self.splitViewController.preferredDisplayMode = UISplitViewControllerDisplayModeOneBesideSecondary;
                
            });
            
        }
        
    }
    
}

#pragma mark - Helpers

- (UIImage *)imageForSortingOption:(YetiSortOption)option {
    
    UIImage *image = nil;
    
    if ([option isEqualToString:YTSortAllDesc]) {
        image = [UIImage systemImageNamed:@"arrow.down.circle"];
    }
    else if ([option isEqualToString:YTSortAllAsc]) {
        image = [UIImage systemImageNamed:@"arrow.up.circle"];
    }
    else if ([option isEqualToString:YTSortUnreadDesc]) {
        image = [UIImage systemImageNamed:@"arrow.down.circle.fill"];
    }
    else if ([option isEqualToString:YTSortUnreadAsc]) {
        image = [UIImage systemImageNamed:@"arrow.up.circle.fill"];
    }
    
    return image;
    
}

@end

static void *UIViewControllerMainCoordinatorKey;

@implementation UIViewController (Coordination)

- (MainCoordinator *)mainCoordinator {
    
    return objc_getAssociatedObject(self, &UIViewControllerMainCoordinatorKey);
    
}

- (void)setMainCoordinator:(MainCoordinator *)mainCoordinator {
    
    objc_setAssociatedObject(self, &UIViewControllerMainCoordinatorKey, mainCoordinator, OBJC_ASSOCIATION_ASSIGN);
    
}

- (void)start {
    
    
    
}

@end

@implementation UIWindow (MacCatalystExtension)

- (nullable NSObject *)innerWindow {
    
    id delegate = [[NSClassFromString(@"NSApplication") sharedApplication] delegate];
    
    const SEL hostWinSEL = NSSelectorFromString([NSString stringWithFormat:@"_%@Window%@Window:", @"host", @"ForUI"]);
    
    @try {
        // There's also hostWindowForUIWindow 🤷‍♂️
        DZS_SILENCE_CALL_TO_UNKNOWN_SELECTOR(id nsWindow = [delegate performSelector:hostWinSEL withObject:self];)
            
        // macOS 11.0 changed this to return an UINSWindowProxy
        SEL attachedWin = NSSelectorFromString([NSString stringWithFormat:@"%@%@", @"attached", @"Window"]);
        
        if ([nsWindow respondsToSelector:attachedWin]) {
            nsWindow = [nsWindow valueForKey:NSStringFromSelector(attachedWin)];
        }
        
        return nsWindow;
    }
    @catch (...) {
        NSLogDebug(@"Failed to get NSWindow for %@.", self);
    }
    
    return nil;
    
}

@end
