//
//  FeedsVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedsHeaderView.h"
#import "BarPositioning.h"

@class Feed;
@class DZSectionedDatasource;
@class DZBasicDatasource;

@interface FeedsVC : UITableViewController <UIViewControllerRestoration, BarPositioning> {
    BOOL _refreshing;
    BOOL _preCommitLoading;
    BOOL _noPreSetup;
    
    NSDate *_sinceDate;
    NSIndexPath *_highlightedRow;
}

@property (nonatomic, weak) FeedsHeaderView *headerView;

@property (nonatomic, strong, readonly) DZSectionedDatasource *DS NS_DEPRECATED_IOS(11, 13.0);
@property (nonatomic, weak, readonly) DZBasicDatasource *DS1, *DS2 NS_DEPRECATED_IOS(11, 13.0);

@property (nonatomic, strong) UITableViewDiffableDataSource *DDS NS_AVAILABLE_IOS(13.0);

@property (nonatomic, copy) NSDate *sinceDate;

- (void)setupData;

- (void)showSubscriptionsInterface;

- (id)objectAtIndexPath:(NSIndexPath *)indexPath;

#pragma mark - Actions Extension

@property (nonatomic, weak) UITextField *alertTextField;
@property (nonatomic, weak) UIAlertAction *alertDoneAction;
@property (nonatomic, weak) Feed *alertFeed;
@property (nonatomic, strong) NSIndexPath *alertIndexPath;

@end
