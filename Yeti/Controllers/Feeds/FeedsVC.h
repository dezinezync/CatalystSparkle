//
//  FeedsVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 14/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Feed;

@interface FeedsVC : UITableViewController {
    BOOL _refreshing;
}

- (void)setupData:(NSArray <Feed *> *)feeds;

@end
