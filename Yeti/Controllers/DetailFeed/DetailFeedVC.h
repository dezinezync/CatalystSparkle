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

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN BOOL IsAccessibilityContentCategory(void);

API_AVAILABLE(ios(13.0))
@interface DetailFeedVC : UICollectionViewController <ScrollLoading, UIViewControllerRestoration, BarPositioning> {
    NSOperation *_searchOperation;
    BOOL _canLoadNext;
    
    NSIndexPath *_highlightedRow;
    BOOL _shouldShowHeader;
}

+ (UINavigationController *)instanceWithFeed:(Feed * _Nullable)feed;

- (instancetype _Nonnull)initWithFeed:(Feed * _Nullable)feed;

@property (nonatomic, assign, getter=isCustomFeed) FeedType customFeed;

@property (nonatomic, assign) NSNumber * _Nullable loadOnReady;

@property (nonatomic, strong) DZBasicDatasource *DS;

@property (nonatomic, getter=isLoadingNext) BOOL loadingNext;

@property (nonatomic, assign, getter=isExploring) BOOL exploring;

@property (nonatomic, strong) Feed * _Nullable feed;

@property (nonatomic, strong) NSOperation * _Nullable searchOperation;

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;

@property (nonatomic, weak) UICollectionViewCompositionalLayout *compLayout NS_AVAILABLE_IOS(13.0);

@property (nonatomic, strong) UISelectionFeedbackGenerator *feedbackGenerator;

@property (assign) NSInteger page;

- (BOOL)showsSortingButton;

- (void)setupHeaderView;

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read;

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked;

- (void)didChangeToArticle:(FeedItem *)item;

@property (nonatomic, strong) NSMutableArray <NSValue *> *sizeCache;

- (void)setupLayout;

- (NSString *)emptyViewSubtitle;

@end

NS_ASSUME_NONNULL_END
