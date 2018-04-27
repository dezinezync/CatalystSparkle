//
//  FeedsVC+Actions.h
//  Yeti
//
//  Created by Nikhil Nigade on 29/11/17.
//  Copyright © 2017 Dezine Zync Studios. All rights reserved.
//

#import "FeedsVC+Search.h"

@interface FeedsVC (Actions) <UITableViewDragDelegate>

- (void)didTapAdd:(UIBarButtonItem *)add;

- (void)didTapAddFolder:(UIBarButtonItem *)add;

- (void)didTapSettings;

- (void)beginRefreshing:(UIRefreshControl *)sender;

- (void)didLongTapOnCell:(UITapGestureRecognizer *)sender;

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
