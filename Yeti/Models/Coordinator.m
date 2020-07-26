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
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:sidebar];
    
    [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnPrimary];
    
    UITraitCollection *traitCollection = UIApplication.sharedApplication.windows.firstObject.traitCollection;
    
    if (traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad
        && traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        EmptyVC *emptyVC = [[EmptyVC alloc] initWithNibName:NSStringFromClass(EmptyVC.class) bundle:nil];
     
        [self.splitViewController setViewController:emptyVC forColumn:UISplitViewControllerColumnSecondary];
        
    }

    
}

- (void)showCustomVC:(CustomFeed *)feed {
    
    if (feed.feedType == FeedVCTypeUnread) {
        
        UnreadVC *unreadVC = [[UnreadVC alloc] init];
        
        [self _showFeedVC:unreadVC];
        
    }
    
}

- (void)_showFeedVC:(FeedVC *)feedVC {
    
    if (feedVC == nil) {
        return;
    }
    
    feedVC.mainCoordinator = self;
    
    if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular
        && self.splitViewController.traitCollection.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:feedVC];
        
        [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnSupplementary];
        
        return;
        
    }
    
    UINavigationController *nav = self.splitViewController.viewControllers.firstObject;
    [nav pushViewController:feedVC animated:YES];
    
}

- (void)showArticleVC:(ArticleVC *)articleVC {
    
    if (articleVC == nil) {
        return;
    }
    
    articleVC.mainCoordinator = self;
    
    if (self.splitViewController.presentedViewController != nil && [self.splitViewController.presentedViewController isKindOfClass:UINavigationController.class]) {
        // in a modal stack
        [(UINavigationController *)[self.splitViewController presentedViewController] pushViewController:articleVC animated:YES];
    }
    else if (self.splitViewController.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:articleVC];

        [self.splitViewController setViewController:nav forColumn:UISplitViewControllerColumnSecondary];
        
    }
    else {
        
        UINavigationController *nav = self.splitViewController.viewControllers.firstObject;
        [nav pushViewController:articleVC animated:YES];
        
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
