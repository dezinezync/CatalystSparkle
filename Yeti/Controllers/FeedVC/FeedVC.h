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

#import "PagingManager.h"

#import "Feed.h"

#import "BookmarksManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, FeedVCType) {
    FeedVCTypeNatural,
    FeedVCTypeUnread,
    FeedVCTypeBookmarks,
    FeedVCTypeToday
};

@interface FeedVC : UITableViewController < ControllerState, ScrollLoading >

@property (nonatomic, weak) Feed * _Nullable feed;

+ (UINavigationController * _Nullable)instanceWithFeed:(Feed * _Nonnull)feed;

- (instancetype _Nullable)initWithFeed:(Feed * _Nonnull)feed;

@property (nonatomic, assign) FeedVCType type;

@property (nonatomic, weak) BookmarksManager *bookmarksManager;

@property (atomic, assign) StateType controllerState;

@property (nonatomic, strong) PagingManager *pagingManager;

#pragma mark - Getters

@property (nonatomic, strong, readonly) UISelectionFeedbackGenerator *feedbackGenerator;

@property (nonatomic, strong, readonly) UITableViewDiffableDataSource *DS;

- (NSUInteger)indexOfItem:(FeedItem * _Nonnull)item retIndexPath:(NSIndexPath * _Nullable)outIndexPath;

- (FeedItem * _Nullable)itemForIndexPath:(NSIndexPath * _Nonnull)indexPath;

#pragma mark - State

- (NSString * _Nonnull)emptyViewSubtitle;

- (UIView * _Nonnull)viewForEmptyDataset;

@end

NS_ASSUME_NONNULL_END
