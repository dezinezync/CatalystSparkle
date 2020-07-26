//
//  FeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 13/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UIViewController+Stateful.h"
#import "UIViewController+ScrollLoad.h"
#import "UITableViewController+KeyboardScroll.h"
#import "ArticleProvider.h"

#import "ArticleCell.h"
#import "ArticleVC.h"

#import "PagingManager.h"

#import "CustomFeed.h"

#import "BookmarksManager.h"
#import "BarPositioning.h"

NS_ASSUME_NONNULL_BEGIN

@interface FeedVC : UITableViewController < ControllerState, ScrollLoading >

@property (nonatomic, weak) Feed * _Nullable feed;

+ (UINavigationController * _Nullable)instanceInNavigationController;

+ (UINavigationController * _Nullable)instanceWithFeed:(Feed * _Nullable)feed;

- (instancetype _Nullable)initWithFeed:(Feed * _Nonnull)feed;

@property (nonatomic, assign) FeedVCType type;

@property (nonatomic, weak) BookmarksManager * _Nullable bookmarksManager;

@property (atomic, assign) StateType controllerState;

@property (nonatomic, strong) PagingManager * _Nullable pagingManager;

#pragma mark - Getters

@property (nonatomic, strong, readonly) UISelectionFeedbackGenerator * _Nonnull feedbackGenerator;

@property (nonatomic, strong, readonly) UITableViewDiffableDataSource <NSNumber *, FeedItem *> * _Nullable DS;

/// Calls setupData: with animated determined on how many articles exist in the paging manager.
- (void)setupData;

- (void)setupData:(BOOL)animated;

- (void)setupNavigationBar;

- (NSUInteger)indexOfItem:(FeedItem * _Nonnull)item retIndexPath:(NSIndexPath * _Nullable)outIndexPath;

- (FeedItem * _Nullable)itemForIndexPath:(NSIndexPath * _Nonnull)indexPath;

#pragma mark - State

- (NSString * _Nonnull)emptyViewSubtitle;

- (UIView * _Nonnull)viewForEmptyDataset;

- (void)continueActivity:(NSUserActivity *)activity;

#pragma mark -

/// Loads the given article ID when the view controller is ready.
@property (nonatomic, assign) NSNumber * _Nullable loadOnReady;

/// Determines if the user is simply exploring this feed from recommendations or somewhere else.
@property (nonatomic, assign, getter=isExploring) BOOL exploring;

- (BOOL)showsSortingButton;

@property (nonatomic, assign) YetiSortOption sortingOption;

- (void)_setSortingOption:(YetiSortOption)option;

#pragma mark - Search Results

@property (nonatomic, copy) successBlock _Nullable searchOperationSuccess;

@property (nonatomic, copy) errorBlock _Nullable searchOperationError;

@property (nonatomic, strong) NSURLSessionTask * _Nullable searchOperation;

- (void)_showArticleVC:(ArticleVC *)vc;

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity;

@end

NS_ASSUME_NONNULL_END
