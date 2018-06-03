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
@class DZBasicDatasource;

@interface FeedsVC : UITableViewController {
    BOOL _refreshing;
    BOOL _preCommitLoading;
    BOOL _noPreSetup;
    
    NSDate *_sinceDate;
    NSIndexPath *_highlightedRow;
}

@property (nonatomic, weak) FeedsHeaderView *headerView;

@property (nonatomic, strong, readonly) DZBasicDatasource *DS;

@property (nonatomic, copy) NSDate *sinceDate;

- (void)setupData:(NSArray <Feed *> *)feeds;

@end
