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

@implementation MainCoordinator

- (instancetype)init {
    
    if (self = [super init]) {
        
        self.childCoordinators = [NSMutableArray arrayWithCapacity:3];
        self.bookmarksManager = [[BookmarksManager alloc] init];
        
    }
    
    return self;
    
}

- (void)start {
    
    if (self.splitViewController == nil) {
        NSAssert(self.splitViewController != nil, @"A split view controller is needed to start the coordinator.");
    }
    
    SidebarVC *sidebar = [SidebarVC instanceWithDefaultLayout];
    sidebar.mainCoordinator = self;
    sidebar.bookmarksManager = self.bookmarksManager;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sidebar];
    
    [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnPrimary];
    
    UITraitCollection *traitCollection = UIApplication.sharedApplication.windows.firstObject.traitCollection;
    
    if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad
        && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
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

#pragma mark - Helpers

- (void)_showSupplementaryController:(UIViewController *)controller {
    
    if (controller == nil) {
        return;
    }
    
    if ([controller isKindOfClass:FeedVC.class]) {
        
        self.feedVC = (FeedVC *)controller;
        
    }
    
    if ([controller isKindOfClass:UINavigationController.class] == NO) {
        
        controller.mainCoordinator = self;
        
        if ([controller isKindOfClass:FeedVC.class] == YES) {
            
            [(FeedVC *)controller setBookmarksManager:self.bookmarksManager];
            
        }
        
    }
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        && self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
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
