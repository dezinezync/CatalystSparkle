//
//  Coordinator.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EmptyVC.h"
#import "ArticleVC.h"

@class SidebarVC;
@class SplitVC;
@class Folder;
@class Feed;
@class CustomFeed;

NS_ASSUME_NONNULL_BEGIN

@interface Coordinator : NSObject

- (void)start;

@end

@interface MainCoordinator : NSObject

@property (nonatomic, assign) NSUInteger totalToday;

@property (nonatomic, assign) NSUInteger totalUnread;

@property (nonatomic, assign) NSUInteger totalBookmarks;

@property (nonatomic, strong) NSMutableArray <Coordinator *> * childCoordinators;

@property (nonatomic, weak) SplitVC *splitViewController;

#pragma mark - Controller References

@property (nonatomic, weak) SidebarVC *sidebarVC;

// @TODO: Change to FeedVC
@property (nonatomic, weak, nullable) ArticleVC *feedVC;

@property (nonatomic, weak, nullable) ArticleVC *articleVC;

@property (nonatomic, weak, nullable) EmptyVC *emptyVC;

@property (nonatomic, weak, nullable) NSObject *innerWindow;

#pragma mark - Methods

- (void)start;

- (void)showCustomVC:(CustomFeed *)feed;

- (void)showFeedVC:(Feed *)feed;

- (void)showFolderFeed:(Folder *)folder;

- (void)showArticleVC:(ArticleVC *)articleVC;

- (void)showEmptyVC;

- (void)showLaunchVC;

- (void)showSubscriptionsInterface;

- (void)showNewFeedVC;

- (void)showNewFolderVC;

- (void)showRenameFolderVC:(Folder *)folder;

- (void)showSettingsVC;

- (void)showContactInterface;

- (void)prepareDataForFullResync;

- (void)prepareFeedsForFullResync;

- (void)registerForNotifications:(void(^ _Nullable)(BOOL granted, NSError * _Nullable error))completion;

- (void)checkForPushNotifications;

- (void)didTapCloseForPushRequest;

- (void)showFeedInfo:(Feed * _Nonnull)feed from:(UIViewController * _Nonnull)viewController;

#if TARGET_OS_MACCATALYST

- (void)showAttributions;

#endif

/*
 * 0: None, 1: Import, 2: Export
 */
- (void)showOPMLInterfaceFrom:(id _Nullable)sender direct:(NSInteger)type;

#pragma mark - Shared Containers

- (void)writeToSharedFile:(NSString *)fileName data:(NSData *)data;

#pragma mark - Helpers

//- (UIImage *)imageForSortingOption:(YetiSortOption)option;

@end

#define DZS_SILENCE_CALL_TO_UNKNOWN_SELECTOR(expression) _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") expression _Pragma("clang diagnostic pop")

@interface UIWindow (MacCatalystExtension)

- (nullable NSObject *)innerWindow;

@end

@interface UIViewController (Coordination)

@property (nonatomic, weak) MainCoordinator *mainCoordinator;

@end

NS_ASSUME_NONNULL_END
