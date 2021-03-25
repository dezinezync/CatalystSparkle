//
//  Coordinator.h
//  Elytra
//
//  Created by Nikhil Nigade on 24/07/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EmptyVC.h"

@class SidebarVC;
@class SplitVC;
@class FeedVC;
@class ArticleVC;

NS_ASSUME_NONNULL_BEGIN

//@interface Coordinator : NSObject
//
//- (void)start;
//
//@end

@interface MainCoordinator : NSObject

@property (nonatomic, assign) NSUInteger totalToday;

@property (nonatomic, assign) NSUInteger totalUnread;

@property (nonatomic, assign) NSUInteger totalBookmarks;

//@property (nonatomic, strong) NSMutableArray <Coordinator *> * childCoordinators;

@property (nonatomic, weak) SplitVC *splitViewController;

#pragma mark - Controller References

@property (nonatomic, weak) SidebarVC *sidebarVC;

@property (nonatomic, weak, nullable) FeedVC *feedVC;

// @TODO
@property (nonatomic, weak, nullable) FeedVC *articleVC;

@property (nonatomic, weak, nullable) EmptyVC *emptyVC;

@property (nonatomic, weak, nullable) NSObject *innerWindow;

#pragma mark - Methods

- (void)start;

- (void)showCustomVC:(id)feed;

- (void)showFeedVC:(id)feed;

- (void)showFolderFeed:(id)folder;

//- (void)showArticleVC:(ArticleVC *)articleVC;

- (void)showArticle:(id)article;

- (void)showEmptyVC;

- (void)showLaunchVC;

- (void)showSubscriptionsInterface;

- (void)showNewFeedVC;

- (void)showNewFolderVC;

- (void)showRenameFolderVC:(id)folder;

- (void)showSettingsVC;

- (void)showContactInterface;

- (void)prepareDataForFullResync;

- (void)prepareFeedsForFullResync;

- (void)showFeedInfo:(id _Nonnull)feed from:(UIViewController * _Nonnull)viewController;

- (void)registerForNotifications:(void(^ _Nullable)(BOOL granted, NSError * _Nullable error))completion;

- (void)checkForPushNotifications;

- (void)didTapCloseForPushRequest;

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
@property (nonatomic, weak) id coordinator;

@end

NS_ASSUME_NONNULL_END
