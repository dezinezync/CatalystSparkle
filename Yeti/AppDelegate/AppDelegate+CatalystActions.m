//
//  AppDelegate+CatalystActions.m
//  Yeti
//
//  Created by Nikhil Nigade on 18/06/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "AppDelegate+CatalystActions.h"

#import "SplitVC.h"
#import "FeedVC+Actions.h"

@implementation AppDelegate (CatalystActions)

- (void)toggleSidebar {
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
    splitVC.primaryColumnIsHidden = !splitVC.primaryColumnIsHidden;
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)setSortingOptionTo:(YetiSortOption)sortOption {
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
    UINavigationController *nav = (UINavigationController *)[splitVC.viewControllers objectAtIndex:1];
    
    if ([[nav visibleViewController] isKindOfClass:FeedVC.class] == NO) {
        return;
    }
    
    [(FeedVC *)[nav visibleViewController] setSortingOption:sortOption];
    
    [UIMenuSystem.mainSystem setNeedsRebuild];
    
}

- (void)setSortingAllDesc {
    
    [self setSortingOptionTo:YTSortAllDesc];
    
}

- (void)setSortingAllAsc {
    
    [self setSortingOptionTo:YTSortAllAsc];
    
}

- (void)setSortingUnreadDesc {
    
    [self setSortingOptionTo:YTSortUnreadDesc];
    
}

- (void)setSortingUnreadAsc {
    
    [self setSortingOptionTo:YTSortUnreadAsc];
    
}

@end
