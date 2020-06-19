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
#import "ArticleVC+Keyboard.h"

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

- (void)goToIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath == nil) {
        return;
    }
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
    FeedsVC *vc = (FeedsVC *)[[(UINavigationController *)[splitVC.viewControllers firstObject] viewControllers] firstObject];
    
    [vc.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    [vc tableView:vc.tableView didSelectRowAtIndexPath:indexPath];
    
}

- (void)goToUnread {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)goToToday {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)goToBookmarks {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:2 inSection:0];
    
    [self goToIndexPath:indexPath];
    
}

- (void)switchToNextArticle {
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
    ArticleVC *vc = (ArticleVC *)[(UINavigationController *)[[splitVC viewControllers] lastObject] visibleViewController];
    
    [vc didTapNextArticle:nil];
    
}

- (void)switchToPreviousArticle {
    
    SplitVC *splitVC = (SplitVC *)[[MyAppDelegate window] rootViewController];
    
    ArticleVC *vc = (ArticleVC *)[(UINavigationController *)[[splitVC viewControllers] lastObject] visibleViewController];
    
    [vc didTapPreviousArticle:nil];
    
}

@end
