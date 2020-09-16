//
//  Coordinator.m
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "Coordinator.h"
#import <objc/runtime.h>

#import "UnreadVC.h"
#import "TodayVC.h"
#import "BookmarksVC.h"
#import "RecommendationsVC.h"
#import "FolderVC.h"
#import "NewFolderVC.h"
#import "LaunchVC.h"
#import "StoreVC.h"
#import "AddFeedVC.h"
#import "NewFolderController.h"
#import "SettingsVC.h"
#import <DZKit/AlertManager.h>

@interface MainCoordinator ()

@property (nonatomic, strong) NewFolderController *folderController;

@end

@implementation MainCoordinator

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.childCoordinators = [NSMutableArray arrayWithCapacity:3];
        self.bookmarksManager = [[BookmarksManager alloc] init];
        
        MyFeedsManager.bookmarksManager = self.bookmarksManager;
        
    }
    
    return self;
    
}

- (void)start {
    
    if (self.splitViewController == nil) {
        NSAssert(self.splitViewController != nil, @"A split view controller is needed to start the coordinator.");
    }
    
    SidebarVC *sidebar = [[SidebarVC alloc] initWithDefaultLayout];
    sidebar.mainCoordinator = self;
    sidebar.bookmarksManager = self.bookmarksManager;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sidebar];
    
    [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnPrimary];
    
    UITraitCollection *traitCollection = UIApplication.sharedApplication.windows.firstObject.traitCollection;
    
    if (traitCollection.userInterfaceIdiom != UIUserInterfaceIdiomPhone
        && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomMac) {
            
            UnreadVC *vc = [[UnreadVC alloc] init];
            
            [self _showSupplementaryController:vc];
            
        }
        
        EmptyVC *emptyVC = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
     
        [self.splitViewController setViewController:emptyVC forColumn:UISplitViewControllerColumnSecondary];
        
    }

    self.sidebarVC = sidebar;
    
}

- (void)showCustomVC:(CustomFeed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    if (feed.feedType == FeedVCTypeUnread) {
        
        UnreadVC *unreadVC = [[UnreadVC alloc] init];
        
        [self _showSupplementaryController:unreadVC];
        
    }
    else if (feed.feedType == FeedVCTypeToday) {
        
        TodayVC *todayVC = [[TodayVC alloc] init];
        
        [self _showSupplementaryController:todayVC];
        
    }
    else if (feed.feedType == FeedVCTypeBookmarks) {
        
        BookmarksVC *bookmarksVC = [[BookmarksVC alloc] init];
        
        [self _showSupplementaryController:bookmarksVC];
        
    }
    
}

- (void)showFeedVC:(Feed *)feed {
    
    if (feed == nil) {
        return;
    }
    
    FeedVC *vc = [[FeedVC alloc] initWithFeed:feed];
    
    [self _showSupplementaryController:vc];
    
}

- (void)showFolderFeed:(Folder *)folder {
    
    if (folder == nil) {
        return;
    }
    
    FolderVC *vc = [[FolderVC alloc] initWithFolder:folder];
    
    [self _showSupplementaryController:vc];
    
}

- (void)showArticleVC:(ArticleVC *)articleVC {
    
    if (articleVC == nil) {
        return;
    }
    
    articleVC.mainCoordinator = self;
    
    [self _showDetailController:articleVC];
    
}

- (void)showRecommendations {
    
    RecommendationsVC *vc = [[RecommendationsVC alloc] initWithNibName:NSStringFromClass(RecommendationsVC.class) bundle:nil];

    [self _showSupplementaryController:vc];
    
}

- (void)showEmptyVC {
    
    EmptyVC *vc = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
    
    [self _showDetailController:vc];
    
}

- (void)showLaunchVC {
    
    if (self.splitViewController.presentingViewController != nil) {
        return;
    }
    
    LaunchVC *vc = [[LaunchVC alloc] initWithNibName:NSStringFromClass(LaunchVC.class) bundle:nil];
    vc.mainCoordinator = self;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalInPresentation = YES;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
}

- (void)showSubscriptionsInterface {
    
    StoreVC *vc = [[StoreVC alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    nav.modalPresentationStyle = UIModalPresentationFormSheet;
    nav.modalInPresentation = YES;
    
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:vc action:@selector(didTapDone:)];
    
    vc.navigationItem.rightBarButtonItem = done;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
}

- (void)showNewFeedVC {
    
    UINavigationController *nav = [AddFeedVC instanceInNavController];
    
    nav.viewControllers.firstObject.mainCoordinator = self;
    
    [self.splitViewController presentViewController:nav animated:YES completion:nil];
    
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

#pragma mark - Helpers

- (void)_showSupplementaryController:(UIViewController *)controller {
    
    if (controller == nil) {
        return;
    }
    
    if ([controller isKindOfClass:FeedVC.class]) {
        
        self.feedVC = (FeedVC *)controller;
        
        [(FeedVC *)controller setBookmarksManager:self.bookmarksManager];
        
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
    
    if ([controller isKindOfClass:ArticleVC.class]) {
        
        self.articleVC = (ArticleVC *)controller;
        
    }
    
    if ([controller isKindOfClass:EmptyVC.class]) {
        
        self.emptyVC = (EmptyVC *)controller;
        
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
        if ([controller isKindOfClass:EmptyVC.class]) {
            return;
        }
        
        UINavigationController *nav = self.splitViewController.viewControllers.firstObject;
        [nav pushViewController:controller animated:YES];
        
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
