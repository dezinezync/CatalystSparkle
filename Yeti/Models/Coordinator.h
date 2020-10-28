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

@property (nonatomic, weak, nullable) NSObject *innerWindow;

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

#if TARGET_OS_MACCATALYST

- (void)showAttributions;

#endif

/*
 * 0: None, 1: Import, 2: Export
 */
- (void)showOPMLInterfaceFrom:(id _Nullable)sender direct:(NSInteger)type;

#pragma mark - Helpers

- (UIImage *)imageForSortingOption:(YetiSortOption)option;

@end

#define DZS_SILENCE_CALL_TO_UNKNOWN_SELECTOR(expression) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") expression _Pragma("clang diagnostic pop")

@interface UIWindow (MacCatalystExtension)

- (nullable NSObject *)innerWindow;

@end

@interface UIViewController (Coordination)

@property (nonatomic, weak) MainCoordinator *mainCoordinator;

@end

NS_ASSUME_NONNULL_END
