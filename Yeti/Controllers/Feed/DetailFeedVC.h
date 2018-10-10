//
//  DetailFeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 09/10/18.
//  Copyright © 2018 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

#import "UIViewController+ScrollLoad.h"
#import <DZKit/DZBasicDatasource.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetailFeedVC : UICollectionViewController <ScrollLoading> {
    NSOperation *_searchOperation;
    NSInteger _page;
    BOOL _canLoadNext;
    
    NSIndexPath *_highlightedRow;
}

+ (UINavigationController *)instanceWithFeed:(Feed *)feed;

- (instancetype _Nonnull)initWithFeed:(Feed * _Nonnull)feed;

@property (nonatomic, assign, getter=isCustomFeed) BOOL customFeed;

@property (nonatomic, assign) NSNumber *loadOnReady;

@property (nonatomic, strong) DZBasicDatasource *DS;

@property (nonatomic, getter=isLoadingNext) BOOL loadingNext;

@property (nonatomic, assign, getter=isExploring) BOOL exploring;

@property (nonatomic, strong) Feed * _Nullable feed;

@property (nonatomic, strong) NSOperation * _Nullable searchOperation;

@property (nonatomic, weak) UICollectionViewFlowLayout *flowLayout;

- (void)setupHeaderView;

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read;

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked;

- (void)didChangeToArticle:(FeedItem *)item;

@end

NS_ASSUME_NONNULL_END
