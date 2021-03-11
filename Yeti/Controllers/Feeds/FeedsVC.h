//
//  FeedsVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BarPositioning.h"

@class Feed;
@class DZSectionedDatasource;
@class DZBasicDatasource;

#define TopSection  @0
#define MainSection @1

@interface FeedsVC : UITableViewController <UIViewControllerRestoration, BarPositioning> {
    BOOL _refreshing;
    BOOL _preCommitLoading;
    BOOL _noPreSetup;
    BOOL _presentingKnown;
    
    NSDate *_sinceDate;
    NSIndexPath *_highlightedRow;
    
    NSUInteger _refreshFeedsCounter;
}

@property (nonatomic, strong) UITableViewDiffableDataSource * _Nonnull DDS;

@property (nonatomic, strong) BookmarksManager *bookmarksManager;

- (void)setupData;

- (void)showSubscriptionsInterface;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

- (void)fetchLatestCounters;

#pragma mark - Actions Extension

@property (nonatomic, weak) UITextField *alertTextField;
@property (nonatomic, weak) UIAlertAction *alertDoneAction;
@property (nonatomic, weak) Feed *alertFeed;
@property (nonatomic, strong) NSIndexPath *alertIndexPath;

- (void)continueActivity:(NSUserActivity *)activity;

- (void)saveRestorationActivity:(NSUserActivity * _Nonnull)activity;

@end
