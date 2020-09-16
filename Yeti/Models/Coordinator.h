//
//  Coordinator.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SplitVC.h"

#import "SidebarVC+SearchResults.h"
#import "FeedVC+SearchController.h"
#import "EmptyVC.h"

NS_ASSUME_NONNULL_BEGIN

@interface Coordinator : NSObject

- (void)start;

@end

@interface MainCoordinator : NSObject

@property (nonatomic, strong) NSMutableArray <Coordinator *> * childCoordinators;

@property (nonatomic, weak) SplitVC *splitViewController;

@property (nonatomic, strong) BookmarksManager *bookmarksManager;

#pragma mark - Controller References

@property (nonatomic, weak) SidebarVC *sidebarVC;

@property (nonatomic, weak, nullable) FeedVC *feedVC;

@property (nonatomic, weak, nullable) ArticleVC *articleVC;

@property (nonatomic, weak, nullable) EmptyVC *emptyVC;

#pragma mark - Methods

- (void)start;

- (void)showCustomVC:(CustomFeed *)feed;

- (void)showFeedVC:(Feed *)feed;

- (void)showFolderFeed:(Folder *)folder;

- (void)showArticleVC:(ArticleVC *)articleVC;

- (void)showRecommendations;

- (void)showEmptyVC;

- (void)showLaunchVC;

- (void)showSubscriptionsInterface;

- (void)showNewFeedVC;

- (void)showNewFolderVC;

- (void)showRenameFolderVC:(Folder *)folder;

- (void)showSettingsVC;

#pragma mark - Helpers

- (UIImage *)imageForSortingOption:(YetiSortOption)option;

@end

@interface UIViewController (Coordination)

@property (nonatomic, weak) MainCoordinator *mainCoordinator;

@end

NS_ASSUME_NONNULL_END
