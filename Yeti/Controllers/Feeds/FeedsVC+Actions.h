//
//  FeedsVC+Actions.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC.h"

@interface FeedsVC (Actions)

- (void)didTapAdd:(UIBarButtonItem *)add;

- (void)beginRefreshing:(UIRefreshControl *)sender;

@end
