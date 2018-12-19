//
//  FeedsVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeedsHeaderView.h"

@class Feed;
@class DZSectionedDatasource;
@class DZBasicDatasource;

@interface FeedsVC : UITableViewController <UIViewControllerRestoration> {
    BOOL _refreshing;
    BOOL _preCommitLoading;
    BOOL _noPreSetup;
    
    NSDate *_sinceDate;
    NSIndexPath *_highlightedRow;
}

@property (nonatomic, weak) FeedsHeaderView *headerView;

@property (nonatomic, strong, readonly) DZSectionedDatasource *DS;
@property (nonatomic, weak, readonly) DZBasicDatasource *DS1, *DS2;

@property (nonatomic, copy) NSDate *sinceDate;

- (void)setupData;

- (void)showSubscriptionsInterface;

#pragma mark - Actions Extension

@property (nonatomic, weak) UITextField *alertTextField;
@property (nonatomic, weak) UIAlertAction *alertDoneAction;
@property (nonatomic, weak) Feed *alertFeed;
@property (nonatomic, strong) NSIndexPath *alertIndexPath;

@end
