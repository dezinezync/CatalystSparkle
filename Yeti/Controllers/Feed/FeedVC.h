//
//  FeedVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Feed.h"

#import "YetiConstants.h"

#import "UIViewController+ScrollLoad.h"
#import <DZKit/DZBasicDatasource.h>

@interface FeedVC : UITableViewController <ScrollLoading> {
    NSOperation *_searchOperation;
    NSInteger _page;
    BOOL _canLoadNext;
    
    NSIndexPath *_highlightedRow;
}

@property (nonatomic, assign) NSNumber *loadOnReady;

@property (nonatomic, strong) DZBasicDatasource *DS;

@property (nonatomic, getter=isLoadingNext) BOOL loadingNext;

@property (nonatomic, assign, getter=isExploring) BOOL exploring;

- (instancetype _Nonnull)initWithFeed:(Feed * _Nonnull)feed;

@property (nonatomic, strong) Feed * _Nullable feed;

@property (nonatomic, strong) NSOperation * _Nullable searchOperation;

- (BOOL)showsSortingButton;

- (void)setupHeaderView;

- (void)userMarkedArticle:(FeedItem *)article read:(BOOL)read;

- (void)userMarkedArticle:(FeedItem *)article bookmarked:(BOOL)bookmarked;

- (void)didChangeToArticle:(FeedItem *)item;

- (void)_didFinishAllReadActionSuccessfully;

#pragma mark -

- (NSString *)emptyViewSubtitle;

- (void)didTapSortOptions:(UIBarButtonItem *)sender;

- (void)setSortingOption:(YetiSortOption)option;

- (void)presentAllReadController:(UIAlertController *)avc fromSender:(id)sender;

@end
