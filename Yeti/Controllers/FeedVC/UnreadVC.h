//
//  UnreadVC.h
//  Yeti
//
//  Created by Nikhil Nigade on 20/05/20.
//  Copyright © 2020 Dezine Zync Studios. All rights reserved.
//

#import "FeedVC+ContextMenus.h"

NS_ASSUME_NONNULL_BEGIN

@interface UnreadVC : FeedVC

- (instancetype)init;

- (void)_setSortingOption:(YetiSortOption)option;

- (void)didBeginRefreshing:(UIRefreshControl *)sender;

@end

NS_ASSUME_NONNULL_END
