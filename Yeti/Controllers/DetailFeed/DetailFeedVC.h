//
//  DetailFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

#import "YetiConstants.h"

#import "UIViewController+ScrollLoad.h"
#import <DZKit/DZBasicDatasource.h>

#import "BarPositioning.h"
#import "UIViewController+Stateful.h"

#import "PagingManager.h"
#import "BookmarksManager.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN BOOL IsAccessibilityContentCategory(void);

@interface DetailFeedVC : UICollectionViewController <ScrollLoading, UIViewControllerRestoration, BarPositioning, ControllerState> {
    NSOperation *_searchOperation;
    BOOL _canLoadNext;
    
    NSIndexPath *_highlightedRow;
    BOOL _shouldShowHeader;
    
    @public
    StateType _controllerState NS_AVAILABLE_IOS(13.0);
    YetiSortOption _sortingOption;
}

+ (UINavigationController *)instanceWithFeed:(Feed * _Nullable)feed;

- (instancetype _Nonnull)initWithFeed:(Feed * _Nullable)feed;

@property (nonatomic, assign, getter=isCustomFeed) FeedType customFeed;

@property (nonatomic, assign) NSNumber * _Nullable loadOnReady;

@property (nonatomic, strong) DZBasicDatasource *DS NS_DEPRECATED_IOS(11.0, 12.3);

@property (nonatomic, strong) UICollectionViewDiffableDataSource *DDS NS_AVAILABLE_IOS(13.0);

@property (nonatomic, getter=isLoadingNext) BOOL loadingNext;

@property (nonatomic, assign, getter=isExploring) BOOL exploring;

@property (nonatomic, strong) Feed * _Nullable feed;

@property (nonatomic, strong) NSOperation * _Nullable searchOperation;

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, weak) UICollectionViewCompositionalLayout *compLayout NS_AVAILABLE_IOS(13.0);

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@property (assign) NSInteger page;

@property (atomic, assign) StateType controllerState NS_AVAILABLE_IOS(13.0);

@property (nonatomic, weak) BookmarksManager *bookmarksManager;

@property (nonatomic, strong) PagingManager * _Nullable pagingManager;

- (BOOL)showsSortingButton;

- (void)setupHeaderView;

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read;

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked;

- (void)didChangeToArticle:(FeedItem *)item;

@property (nonatomic, strong) NSMutableArray <NSValue *> *sizeCache;

- (void)setupLayout;

- (void)setupData;

- (UIView *)viewForEmptyDataset;

- (NSString *)emptyViewSubtitle;

- (NSUInteger)indexOfItem:(FeedItem * _Nonnull)item retIndexPath:(NSIndexPath * _Nullable)indexPath;

- (FeedItem * _Nullable)itemForIndexPath:(NSIndexPath * _Nonnull)indexPath;

@end

NS_ASSUME_NONNULL_END
